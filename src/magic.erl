%---------------------------------------------------------------------
% FILE:              compiler.erl
% DESCRIPTION:       Magic Database Compiler - Mime Type Detector
% DATE:              05/09/2011
% LANGUAGE PLATFORM: Erlang 5.7.4
% OS PLATFORM:       Ubuntu 2.6.35-28
% AUTHOR:            Murat Aydos  &  Mustafa Yavuz  &  Ersan V. Zorlu
% EMAIL:             aydosmurat@gmail.com  &  89.Yavuz@gmail.com  & ersanvuralzorlu@gmail.com
%---------------------------------------------------------------------

%---------------------------------------------------------------------------------------------------------------
% Compiler Module
% To be able to run getMimeType(FileName), you must run compile() function that creates the magic_db module.
% Running compile() function only once is enough.
%---------------------------------------------------------------------------------------------------------------

%----------------------------------Not Handled Case-------------------------------------------------------------
% "indirect" type case is unhandled. ex: mp3 files' mime-type is determined by this indirect type
% ex: 'audio' file in Magdir : ">(6.I)	indirect	x	\b, contains:"
%---------------------------------------------------------------------------------------------------------------

% ----- SuperLurker Notes
% The magic_db module have been pre-compiled.
% There is no need for TestFolder nor Magdir.
% Project github : https://github.com/murataydos/MimeType-Erlang

-module(magic).
-compile(export_all).
-import(magic_db, [getDB/0]).


-define(MAX_BYTES_TO_READ,102400).
-define(MAGICDB, "magic_db").
-define(MAGDIR, "Magdir/").
-define(TESTFOLDER, "TestFolder").


% Test function that returns the compiled form of test.db file
compileTest() -> compileHelper(["../test.db"], []).

%---------------------------------------------------------------------------------------------------------------
% Database Compiler. 
% Compiles the files in "Magdir" Folder.
% Creates magic_db module file and compile it.
%---------------------------------------------------------------------------------------------------------------
compile() -> CompiledDb = compileHelper(getFileNames(), []),
			file:write_file(?MAGICDB ++".erl", "-module("++ ?MAGICDB ++").\n-compile(export_all).\n\ngetDB() ->"),
			file:write_file(?MAGICDB ++".erl", io_lib:fwrite("~p.\n", [CompiledDb]), [append]),
			compile:file(magic_db, [return]).
			
compileHelper([], Accum) -> Accum;
compileHelper(FileList, Accum) ->
	case file:open(?MAGDIR ++hd(FileList),[read,binary]) of
		{error, _} ->
			compileHelper(tl(FileList), Accum);
		{ok, IoMagic} ->
			ReverseMagicList  = parse_all_lines(IoMagic, [], -1),
			MagicList = lists:reverse(ReverseMagicList),
			compileHelper(tl(FileList), Accum ++ MagicList)
	end.

%---------------------------------------------------------------------------------------------------------------
% Detect Part
%---------------------------------------------------------------------------------------------------------------
% That is the main function takes a filename as argument and starts to test for its mime type.
%---------------------------------------------------------------------------------------------------------------
getMimeType(FileName) when is_list(FileName) -> 
	{ok, Data} = file:read_file(FileName),
	getMimeType(Data);
getMimeType(FileData) when is_binary(FileData) ->
	case dbDetect( FileData ) of
		<<"Unknown Type">> ->
			textType(FileData);
		<<"application/x-dosexec">> -> "application/octet-stream";
		<<"application/zip">> -> detectDocx(FileData);
		MimeType ->
			print(MimeType) 
	end.

%Gets an opened file as argument and returns the compareMagicList() function
dbDetect(<<>>) -> <<"Unknown Type">>;
dbDetect({error, _}) -> <<"File does not exist.">>;
dbDetect(FileData) ->
	MagicList = getDB(),
	compareMagicList(FileData,MagicList, false).

%-------------------------------------------------------------------------------------------------------------------------------------
% Gets the file names in Magdir folder
%---------------------------------------------------------------------------------------------------------------
getFileNames() -> 
		{ok, FileList} = file:list_dir(?MAGDIR),
		FileList.

isElementOf([], _) -> false;
isElementOf(List, Element) ->
	case hd(List) of
		Element -> true;
		_Else -> isElementOf(tl(List), Element)
	end.

%---------------------------------------------------------------------------------------------------------------
% Compares the FileData with a given list of Database Tree
%---------------------------------------------------------------------------------------------------------------
compareMagicList(_, [], _) -> <<"Unknown Type">>;
compareMagicList(FileData, [HeadTree | TailList], ParentAccepted) ->
	case compareTree(FileData, HeadTree, ParentAccepted) of
		<<"Unknown Type">> -> compareMagicList(FileData, TailList, false);
		<<"empty">> -> compareMagicList(FileData, TailList, false);			
		Result -> Result
	end.

%---------------------------------------------------------------------------------------------------------------
% Compares the FileData with a given Database Tree.
% Returns the mime-type of File if the compare result is a mime-type 
% otherwise, the function returns <<"Unknown Type">> or <<"empty">> 
%---------------------------------------------------------------------------------------------------------------
compareTree(FileData, Tree, ParentAccepted) -> 
	Node = treeNode(Tree),
	case typeOf(Node) of
		{search, _} ->
			Node2 = changeNodeType(Node, {string, []}),
			NewNode = changeNodeData(Node2, deleteSpace(dataOf(Node2), <<>>)),
			Flag = 1;
		{byte, _, _, _} ->
			case dataOf(Node) of
				<<"versionX">> -> 
					if ParentAccepted == true ->
						   case mimeOfNode(Tree) of
							   [] -> 
								   Flag = 0, 
								   NewNode = <<"empty">>;
							   [MimeType] -> 
								   Flag = 0,
								   NewNode = MimeType
						   end;
					true -> Flag = 0,
							NewNode = <<"Unknown Type">>
					end;
				_Else3 -> Flag = 1, 
						  NewNode = Node
			end;
		{regex, _} ->
			Regex = dataOf(Node),
			Offset = offsetOf(Node),
			Len = length(binary_to_list(FileData)),
			if Len > Offset ->
				FileContext = string:sub_string(binary_to_list(FileData), Offset+1),
				case re:run(FileContext, binary_to_list(Regex)) of
					nomatch -> Flag = 0, 
							   NewNode = <<"Unknown Type">>;
					_Else4 -> Flag = 0,
							  case mimeOfNode(Tree) of
								  [] -> NewNode = <<"empty">>;
								  [MimeType] -> NewNode = MimeType
							  end
				end;
			true -> Flag = 0,
					NewNode = <<"Unknown Type">>
			end;
		_else -> Flag = 1, 
				 NewNode = Node
	end,
	case Flag of
		1 ->
			case compare(FileData, [NewNode]) of
				<<"Unknown Type">> -> <<"Unknown Type">>;
				<<>> ->
					case mimeOfNode(Tree) of
						[] ->
							case children(Tree) of
								[] -> <<"empty">>;
								Children -> compareMagicList(FileData, Children, true)
							end;
						[Mime] -> Mime
					end;	
				<<"Microsoft Office Document">> -> officeType(FileData);%<<"application/vnd.ms-office">>;
				_Else ->
					case mimeOfNode(Tree) of
						[] -> 
							case children(Tree) of
								[] -> <<"empty">>;
								Children ->
									case compareMagicList(FileData, Children, true) of
										<<"Unknown Type">> -> <<"empty">>;
										MimeResult -> MimeResult
									end
							end;
						[Mime] -> Mime
					end	
			end;
		
		0 -> NewNode
	end.

%---------------------------------------------------------------------------------------------------------------
% Tree Definition
% ex: {node, [{child1, []}, {child2, []}]}
%---------------------------------------------------------------------------------------------------------------
createNode(Node) -> {Node, [], []}.
children({_, Children, _}) -> Children.
treeNode({Node, _, _}) -> Node.
mimeOfNode({_, _, Mime}) -> Mime.

addChild(Tree, Child, 1) -> {treeNode(Tree), [createNode(Child)] ++ children(Tree), mimeOfNode(Tree) };
addChild(Tree, Child, Height) -> 
	case length(children(Tree)) of
		0 ->	Tree;
		_Else ->	{treeNode(Tree), [addChild(hd(children(Tree)), Child, Height -1)] ++ tl(children(Tree)), mimeOfNode(Tree) }
	end.
changeNodeMime(Tree, Mime, 0) -> {treeNode(Tree), children(Tree), [Mime]};
changeNodeMime(Tree, Mime, Height) ->
	case length(children(Tree)) of
		0 -> Tree;
		_Else ->	{treeNode(Tree), [changeNodeMime(hd(children(Tree)), Mime, Height -1)] ++ tl(children(Tree)), mimeOfNode(Tree) }
	end.

%---------------------------------------------------------------------------------------------------------------
offsetOf({{Offset, _}, _, _, _}) -> Offset.
typeOf({_, Type, _, _}) -> Type.
dataOf({_,_,{_, Data},_}) -> Data.
resultOf({_,_,_, Result}) -> Result.

changeNodeType({Offset, _,Data,Mime}, NewType) -> {Offset, NewType, Data, Mime}.
changeNodeData({Offset, Type,{Op, _},Mime}, NewData) -> {Offset, Type, {Op,NewData}, Mime}.

%---------------------------------------------------------------------------------------------------------------
% Read lines from the magic files and store it in a tree form.
% This function is the most important part of compiling magic database.
%---------------------------------------------------------------------------------------------------------------
parse_all_lines(Device, Accum, LastAdded) ->
    case io:get_line(Device, "") of
		eof -> file:close(Device), Accum;
		<<$!, T/binary>> ->
			case parseMime(T) of
        		{ok, Rest} -> 
        			if (LastAdded /= -1) ->
		    			NewHead = changeNodeMime(hd(Accum), Rest, LastAdded),
		    			parse_all_lines(Device, [NewHead] ++ tl(Accum), LastAdded);
        			true ->
        				parse_all_lines(Device, Accum, LastAdded)
        			end;	
        		{err, _} ->
        			parse_all_lines(Device, Accum, LastAdded)
        	end;
		<<$>, T/binary>> ->
			Count = countChar(T, 1),
			Rt = lowerLevel(T),
			case parse(Rt) of 
				[] ->	parse_all_lines(Device, Accum, -1);
				[ParserResult] ->
					case length(Accum) of
						0 -> parse_all_lines(Device, Accum, LastAdded);
						_Else ->
							Tree = hd(Accum),
							NewTree = addChild(Tree, ParserResult, Count),
							parse_all_lines(Device, [NewTree] ++ tl(Accum), Count)
					end
			end;
		Line ->
			case parse(Line) of
				[] -> parse_all_lines(Device, Accum, -1);
				[ParsedLine] ->
					Node = createNode(ParsedLine),
					parse_all_lines(Device, [Node] ++ Accum, 0)
			end
	end.

%---------------------------------------------------------------------------------------------------------------
% Example Line: >>3	string	ID3	FileType
% The number of '>' char is the level of the line.
% lowerLevel makes the level zero.
% ex: lowerLevel(<<">>3\t\string\tID3\FileType">>) -> <<"3\t\string\tID3\FileType">>
%---------------------------------------------------------------------------------------------------------------
lowerLevel(<<>>) -> <<>>;
lowerLevel(<<$>, T/binary>>) ->
	case T of 
		<<$>, R/binary>> -> lowerLevel(R);
		_Else -> T
	end;
lowerLevel(Binary) -> Binary.


%---------------------------------------------------------------------------------------------------------------
% Counts the number of '>' character. ex: countChar(<<">>>line">>) -> 3
%---------------------------------------------------------------------------------------------------------------
countChar(<<$>, R/binary>>, C) -> countChar(R, C+1);
countChar(_, C) -> C.

deleteSpace(<<>>, Accum) -> Accum;
deleteSpace(<<$\s, T/binary>>, <<Accum/binary>>) -> deleteSpace(T, Accum);
deleteSpace(<<Char, T/binary>>, <<Accum/binary>>) -> deleteSpace(T, <<Accum/binary, Char>>).

%---------------------------------------------------------------------------------------------------------------
% Returns the mime-type from the argument line. ex: parseMime(<<":mime audio/mpeg">>) -> <<"audio/mpeg">>
%---------------------------------------------------------------------------------------------------------------
parseMime( <<":mime", $\t, T/binary>> ) -> parseMime2(T, <<>>);
parseMime( <<":mime", $\s, T/binary>> ) -> parseMime2(T, <<>>);
parseMime(Binary) -> {err, Binary}.

parseMime2(<<$\n, _/binary>>, Mime) -> {ok, Mime};
parseMime2(<<>>, Mime) -> {ok, Mime};
parseMime2(<<Char, T/binary>>, Mime) -> parseMime2(T, <<Mime/binary, Char>> ).

%---------------------------------------------------------------------------------------------------------------
% If the file mime-type is "application/zip",
% this function is called to detect wheather the file is an office document.
%---------------------------------------------------------------------------------------------------------------
detectDocx(FileData) -> 
	case zip:list_dir(FileData) of
		{ok, ZipList} -> typeOfZip(tl(ZipList), []);
		{error, _} -> "application/zip"
	end.
	

typeOfZip([], CountList) -> 
	X1 = lists:member(1, CountList),
	X2 = lists:member(2, CountList),
	X3 = lists:member(3, CountList),
	if X1 and X2 and X3 ->
		   X4 = lists:member(4, CountList),
		   X5 = lists:member(5, CountList),
		   X6 = lists:member(6, CountList),
		   Y1 = tff(X4, X5, X6),
		   if Y1 ->
				  "application/msword";
			  true ->
				  Y2 = tff(X5, X4, X6),
				  if Y2 ->
						 "application/vnd.ms-excel";
					 true ->
						 Y3 = tff(X6, X4, X5),
						 if Y3 ->
								"application/vnd.ms-powerpoint";
							true ->
								"application/zip"
						 end
				  end
		   end;
		true -> "application/zip"
	end;	
typeOfZip(ZipList, CountList) ->
	%erlang:display(ZipList),
	{_, Head, _, _, _, _} = hd(ZipList),
	case hd(string:tokens(Head, "/")) of
		"[Content_Types].xml" -> typeOfZip(tl(ZipList), CountList ++ [1]);
		"_rels" -> typeOfZip(tl(ZipList), CountList ++ [2]);
		"docProps" -> typeOfZip(tl(ZipList), CountList ++ [3]);
		"word" -> 
			case isWordDocx(ZipList, []) of
				{true, ZipTail} -> 	typeOfZip(ZipTail, CountList ++ [4]);
				{false, ZipTail} -> typeOfZip(ZipTail, CountList)
			end;
		"xl" ->
			case isExcelXlsx(ZipList, []) of
				{true, ZipTail} -> typeOfZip(ZipTail, CountList ++ [5]);
				{false, ZipTail} -> typeOfZip(ZipTail, CountList)
			end;
		"ppt" ->
			case isPowerpointPptx(ZipList, []) of
				{true, ZipTail} -> typeOfZip(ZipTail, CountList ++ [6]);
				{false, ZipTail} -> typeOfZip(ZipTail, CountList)
			end;
		_Else -> typeOfZip(tl(ZipList), CountList)
	end.

isWordDocx(ZipList, CountList) ->
	{_, Head, _, _, _, _} = hd(ZipList),
	Folder = string:tokens(Head, "/"),
	case hd(Folder) of
		"word" -> 
			if length(Folder) > 1 ->
				case hd(tl(Folder)) of
					"styles.xml" -> isWordDocx(tl(ZipList),CountList ++ [1]);
					"document.xml" -> isWordDocx(tl(ZipList),CountList ++ [2]);
					"fontTable.xml" -> isWordDocx(tl(ZipList),CountList ++ [3]);
					_Else -> isWordDocx(tl(ZipList),  CountList)
				end;
			   true -> 
				   {false, tl(ZipList)}
			end;
		_Else ->
			{DocList, Rest} = scanRest("word", ZipList, [], []),
			if length(DocList) > 0 ->
				   isWordDocx(DocList ++ Rest,  CountList);
			   true ->
					X1 = lists:member(1, CountList),
					X2 = lists:member(2, CountList),
					X3 = lists:member(3, CountList),
					if X1 and X2 and X3 ->
						   {true, ZipList};
					   true ->
						   {false, ZipList}
					end
			end
	end.

isExcelXlsx(ZipList, CountList) ->
	{_, Head, _, _, _, _} = hd(ZipList),
	Folder = string:tokens(Head, "/"),
	case hd(Folder) of
		"xl" -> 
			if length(Folder) > 1 ->
				case hd(tl(Folder)) of
					"_rels" -> isExcelXlsx(tl(ZipList), CountList ++ [1]);
					"printerSettings" -> isExcelXlsx(tl(ZipList), CountList ++ [2]);
					"theme" -> isExcelXlsx(tl(ZipList), CountList ++ [3]);
					"worksheets" -> isExcelXlsx(tl(ZipList),  CountList ++ [4]);
					"sharedStrings.xml" -> isExcelXlsx(tl(ZipList),  CountList ++ [5]);
					"styles.xml" -> isExcelXlsx(tl(ZipList),  CountList ++ [6]);
					"workbook.xml" -> isExcelXlsx(tl(ZipList),  CountList ++ [7]);
					_Else -> isExcelXlsx(tl(ZipList),  CountList)
				end;
			true -> {false, tl(ZipList)}
			end;
		_Else ->
			{XlList, Rest} = scanRest("xl", ZipList, [], []),
			if length(XlList) > 0 ->
				   isExcelXlsx(XlList ++ Rest,  CountList);
			   true ->
					X1 = lists:member(1, CountList),
					X2 = lists:member(2, CountList),
					X3 = lists:member(3, CountList),	
					X4 = lists:member(4, CountList),
					X5 = lists:member(5, CountList),
					X6 = lists:member(6, CountList),
					X7 = lists:member(7, CountList),
					if X1 and X2 and X3 and X4 and X5 and X6 and X7 ->
						   {true, ZipList};
					   true -> {false, ZipList}
					end
			end
	end.

isPowerpointPptx(ZipList, CountList) ->
	{_, Head, _, _, _, _} = hd(ZipList),
	Folder = string:tokens(Head, "/"),
	case hd(Folder) of
		"ppt" -> 
			if length(Folder) > 1 ->
				case hd(tl(Folder)) of
					"_rels" -> isPowerpointPptx(tl(ZipList), CountList ++ [1]);
					"slideLayouts" -> isPowerpointPptx(tl(ZipList),  CountList ++ [2]);
					"slideMasters" -> isPowerpointPptx(tl(ZipList),  CountList ++ [3]);
					"slides" -> isPowerpointPptx(tl(ZipList), CountList ++ [4]);
					"theme" -> isPowerpointPptx(tl(ZipList),  CountList ++ [5]);
					"presentation.xml" -> isPowerpointPptx(tl(ZipList),  CountList ++ [6]);
					"presProps.xml" -> isPowerpointPptx(tl(ZipList),  CountList ++ [7]);
					"tableStyles.xml" -> isPowerpointPptx(tl(ZipList),  CountList ++ [8]);
					"viewProps.xml" -> isPowerpointPptx(tl(ZipList),  CountList ++ [9]);
					_Else -> isPowerpointPptx(tl(ZipList), CountList)
				end;
			   true -> {false, tl(ZipList)}
			end;
		_Else ->
			{PptList, Rest} = scanRest("ppt", ZipList, [], []),
			if length(PptList) > 0 ->
				   isPowerpointPptx(PptList ++ Rest,  CountList);
			   true ->
					X1 = lists:member(1, CountList),
					X2 = lists:member(2, CountList),
					X3 = lists:member(3, CountList),
					X4 = lists:member(4, CountList),
					X5 = lists:member(5, CountList),
					X6 = lists:member(6, CountList),
					X7 = lists:member(7, CountList),
					X8 = lists:member(8, CountList),
					X9 = lists:member(9, CountList),
					if X1 and X2 and X3 and X4 and X5 and X6 and X7 and X8 and X9 ->
						   {true, ZipList};
					   true -> {false, ZipList}
					end
			end
	end.
					
scanRest(_, [], StringList, RestList) -> {StringList, RestList} ;
scanRest(String, [Zip | Tail], StrList, RestList) ->
	{_, Head, _, _, _, _} = Zip,
	case hd(string:tokens(Head, "/")) of
		String -> scanRest(String, Tail, StrList ++ [Zip], RestList);
		_Else ->scanRest(String, Tail, StrList, RestList ++ [Zip])
	end.

tff(true, _, false) -> true;
tff(true, false, _) -> true;
tff(_, true, true) -> false;
tff(false, _, _) -> false.

%---------------------------------------------------------------------------------------------------------------
% If the file type is "Microsoft Office Document", 
% this function is called to determine the mime-type wheather it is Word, Excel or Powerpoint.
%---------------------------------------------------------------------------------------------------------------
officeType(FileData) ->
	Text = binary_to_list(FileData),
	case string:str(Text, "Microsoft Office Word") of
		0 ->
			case string:str(Text, "Microsoft Excel") of
				0 ->
					case string:str(Text, "Powerpoint") of 
						0 -> case string:str(Text, "Crystal Reports") of
								 0 -> <<"application/vnd.ms-office">>;
								 _Else -> <<"application/x-rpt">>
							 end;
						_Else -> <<"application/vnd.ms-powerpoint">>
					end;
				_Else -> <<"application/vnd.ms-excel">>
			end;
		_Else -> <<"application/msword">>
	end.


%---------------------------------------------------------------------------------------------------------------
% Counts the number of the words in names() and determine the text type. ex: text/x-c
%---------------------------------------------------------------------------------------------------------------
textType(FileData) ->
	<<FileContext:?MAX_BYTES_TO_READ/binary, _/binary>> = FileData,
	case isAsciiText(FileContext, 0, length(FileContext)) of
		false -> "application/octet-stream";
		true ->
			TypeList = wordMatch(FileContext, 0, []),
			{Type, Count} = typeCount(TypeList, 0, []),
			if Count < 5 ->
				"text/plain";
			true -> textTypeResult(Type)
			end
	end.

%---------------------------------------------------------------------------------------------------------------
% Checks whether the text has ascii characters or not
% If the half of the characters are in ascii table, returns true
%---------------------------------------------------------------------------------------------------------------
isAsciiText([], Count, Len) -> 
	Len2 = Len / 3,
	Count < Len2;
isAsciiText(Text, Count, Len) ->
	Char = hd(Text),
	if (Char >31) and (Char < 127) ->
		   isAsciiText(tl(Text), Count, Len);
	true -> isAsciiText(tl(Text), Count+1, Len)
	end.

%---------------------------------------------------------------------------------------------------------------
% Finds out the number of the specific words in FileContext and returns a list
% ex: returns [{"java", 3}, {"c", 3}, {"cc", 5}, {"c", 2}]
%---------------------------------------------------------------------------------------------------------------
wordMatch(FileContext, Index, Accum) ->
	case names(Index) of 
		{error} -> Accum;
		{Word, Type} -> 
			Len = countWord(FileContext, Word, 0),
			wordMatch(FileContext, Index+1, Accum ++ [{Type, Len}])
	end.

% Counts a word in text
countWord("", _, Count) -> Count;
countWord(Text, Word, Count) ->
	case string:str(Text, Word) of
		0 -> Count;
		Place -> 
			NewText = string:substr(Text, Place + length(Word)),
			countWord(NewText, Word, Count +1)
	end.

%---------------------------------------------------------------------------------------------------------------
% Returns a list of joined type counts
% ex: TypeList= [{"html",3}, {"c", 5}, {"html", 2}, {"c", 3}] -> returns [{"html", 5}, {"c", 8}]
%---------------------------------------------------------------------------------------------------------------
typeCount(TypeList, Index, Accum) ->
	case shortType(Index) of
		{error} -> findTextResult(Accum, [{"Type", 0}], []);
		Type ->
			typeCount(TypeList, Index+1, Accum ++ [typeListCountType(Type, TypeList, 0)])
	end.

%---------------------------------------------------------------------------------------------------------------
% Joins the type counts of Type and returns
% ex: Type = "html" and TypeList = [{"html",3}, {"c", 5}, {"html", 2}] -> returns {"html", 5}
%---------------------------------------------------------------------------------------------------------------
typeListCountType(Type, [], Count) -> {Type, Count};
typeListCountType(Type, [Head | TypeList], Count) ->
	case Type of
		"c" ->
			case textTypeOf(Head) of
				"c" -> typeListCountType(Type, TypeList, Count + typeCountOf(Head) );
				"cc" -> typeListCountType(Type, TypeList, Count + typeCountOf(Head) );
				_Else -> typeListCountType(Type, TypeList, Count)
			end;
		_Else ->
			case textTypeOf(Head) of
				Type -> typeListCountType(Type, TypeList, Count + typeCountOf(Head) );
				_Else2 -> typeListCountType(Type, TypeList, Count)
			end
	end.

%---------------------------------------------------------------------------------------------------------------
% Determine the type of text according to the number of type counts
% ex: {"java", 10} can be a member of TypeCountList if there are 10 words of "java" in text.
%---------------------------------------------------------------------------------------------------------------
findTextResult([], [Result], Accum) -> textCompare(Result, Accum);
findTextResult([Head | TypeCountList], [Result], Accum) ->
	Htype = textTypeOf(Head),
	Hcount = typeCountOf(Head),
	case Htype of
		"cc" ->
			if Hcount > 5 ->
				   NewAccum = [Head] ++ Accum;
			   true ->
				   NewAccum = Accum
			end;
		"c" ->
			if Hcount > 5 ->
				   NewAccum = [Head] ++ Accum;
			   true ->
				   NewAccum = Accum
			end;
		"java" ->
			if Hcount > 0 ->
				   NewAccum = [Head] ++ Accum;
			   true ->
				   NewAccum = Accum
			end;
		"html" ->
			if Hcount > 3 ->
				   NewAccum = [Head] ++ Accum;
			   true ->
				   NewAccum = Accum
			end;
		_Else -> NewAccum = Accum
	end,
	Rcount = typeCountOf(Result),
	if Hcount > Rcount ->
		   findTextResult(TypeCountList, [Head], NewAccum);
	   true ->
		   findTextResult(TypeCountList, [Result], NewAccum)
	end.

% order cc, c, java, html counts
orderTypes([], Ordered) -> Ordered;
orderTypes([Head | Types], {Cc, C, Java, Html}) ->
	case textTypeOf(Head) of
		"cc" -> orderTypes(Types, {typeCountOf(Head), C, Java, Html});
		"c" -> orderTypes(Types, {Cc, typeCountOf(Head), Java, Html});
		"Java" -> orderTypes(Types, {Cc, C, typeCountOf(Head), Html});
		"Html" -> orderTypes(Types, {Cc, C, Java, typeCountOf(Head)});
		_Else -> orderTypes(Types,{Cc, C, Java, Html})
	end.

%---------------------------------------------------------------------------------------------------------------
% Compares the number of cc, c, java, html words
% Returns the Result of findTextResult() if the numbers of words are inappropriate
%---------------------------------------------------------------------------------------------------------------
textCompare(MostCommon, Types) ->
	{Cc, C, Java, Html} = orderTypes(Types, {0,0,0,0}),
	if Html > 5 ->
		{"html", Html};
	true ->
		if (Java > 0) and (Cc > 5) ->
			{"java", Cc};
		true ->
			C_dif = C - Cc,
			if C_dif > 5 ->
				{"c", C};
			true ->
				if C > 5 ->
					{"cc", C};
				true ->
					MostCommon
				end
			end
		end
	end.
		
textTypeOf({X, _}) -> X.
typeCountOf({_, Y}) -> Y.

%---------------------------------------------------------------------------------------------------------------
% Returns the element at the Index of List
%---------------------------------------------------------------------------------------------------------------
elementAt([], _) -> {error};
elementAt(List, 0) -> hd(List);
elementAt(List, Index) ->
	elementAt(tl(List), Index-1).	

%---------------------------------------------------------------------------------------------------------------
% Returns the type word at the specific index
% ex. "template" is a "cc" word.
%---------------------------------------------------------------------------------------------------------------
names(Index) ->
	elementAt(
	[
	{"msgid",	"po"},
	{"dnl",		"m4"},
	{"import",	"java"},
	{"\"libhdr\"",	"bcpl"},
	{"\"LIBHDR\"",	"bcpl"},
	{"template","cc"},
	{"virtual",	"cc"},
	{"class",	"cc"},
	{"public:",	"cc"},
	{"private:","cc"},
	{"/*",		"cc"},
	{"#include","cc"},
	{"char",	"c"},
	{"double",	"c"},
	{"extern",	"c"},
	{"float",	"c"},
	{"struct",	"c"},
	{"union",	"c"},
	{"CFLAGS",	"make"},
	{"LDFLAGS",	"make"},
	{"all:",	"make"},
	{".PRECIOUS",	"make"},
	{".ascii",	"mach"},
	{".asciiz",	"mach"},
	{".byte",	"mach"},
	{".even",	"mach"},
	{".globl",	"mach"},
	{".text",	"mach"},
	{"clr",		"mach"},
	{"(input,",	"pas"},
	{"program",	"pas"},
	{"record",	"pas"},
	{"dcl",		"pli"},
	{"Received:",	"mail"},
	{">From",	"mail"},
	{"Return-Path:","mail"},
	{"Cc:",		"mail"},
	{"Newsgroups:",	"news"},
	{"Path:",	"news"},
	{"Organization:","news"},
	{"href=",	"html"},
	{"HREF=",	"html"},
	{"<body",	"html"},
	{"<BODY",	"html"},
	{"<html",	"html"},
	{"<HTML",	"html"},
	{"<!--",	"html"}
	],
	Index).

% Returns the type at the specific index.
shortType(Index) ->
	elementAt(["c", "cc", "make", "pli", "mach", "eng", "pas", "mail", "news", "java", "html", "bcpl", "m4", "po"], Index).

%---------------------------------------------------------------------------------------------------------------
% Returns the mime-type of Type
%---------------------------------------------------------------------------------------------------------------
textTypeResult(Type) ->
	case Type of
		"c" -> "text/x-c";
		"cc" -> "text/x-c++";
		"make" -> "text/x-makefile";
		"pli" -> "text/x-pl1";
		"mach" -> "text/x-asm";
		"eng" -> "text/plain";
		"pas" -> "text/x-pascal";
		"mail" -> "text/x-mail";
		"news" -> "text/x-news";
		"java" -> "text/x-java";
		"html" -> "text/html";
		"bcpl" -> "text/x-bcpl";
		"m4" -> "text/x-m4";
		"po" -> "text/x-po"
	end.

%---------------------------------------------------------------------------------------------------------------
% Prints result.
%---------------------------------------------------------------------------------------------------------------
print(<<$\s,T/binary>>) -> print(T);
print(Result) -> binary_to_list(Result).

%---------------------------------------------------------------------------------------------------------------
% Checks whether a given digit is available for Decimal , Hexadecimal and Octal or not.
%---------------------------------------------------------------------------------------------------------------
isDecDigit(Char) -> (Char >= $0) and (Char =< $9).
isOctDigit(Char) -> (Char >= $0) and (Char =< $7).
isHexDigit(Char) -> (Char >= $0) and (Char =< $9) or
						(Char >= $a) and (Char =< $f) or
						(Char >= $A) and (Char =< $F).


%---------------------------------------------------------------------------------------------------------------
% This functions takes binary type as argument and returns if it is Decimal, Hex or Octal number.
%---------------------------------------------------------------------------------------------------------------
isDec(<<>>) -> false;
isDec(Var) -> << <<X>> || <<X>> <= Var , isDecDigit(X) >> == Var.

isHex(<<>>) -> false;
isHex(Var) -> << <<X>> || <<X>> <= Var , isHexDigit(X) >> == Var.

isOct(<<>>) -> false;
isOct(Var) -> << <<X>> || <<X>> <= Var , isOctDigit(X) >> == Var.


%---------------------------------------------------------------------------------------------------------------
% This functions takes binary type as argument and converts it into Decimal from Hexadecimal,Octal,Decimal.
%---------------------------------------------------------------------------------------------------------------
hex2int(Hex) ->
    erlang:list_to_integer((erlang:binary_to_list(Hex)), 16).
    
oct2int(Hex) ->
    erlang:list_to_integer((erlang:binary_to_list(Hex)), 8).
       
dec2int(Hex) ->
    erlang:list_to_integer((erlang:binary_to_list(Hex)), 10).

%---------------------------------------------------------------------------------------------------------------
% This function converts hex,oct or dec (e.g. 0xaef32 , 01242 , 3563) to decimal.
%---------------------------------------------------------------------------------------------------------------
hdo2int(<<$0>>) -> 0 ;
hdo2int(<<$0 , $x, T/binary>>) -> hex2int(T);
hdo2int(<<$0 , T/binary>> ) -> oct2int(T);
hdo2int(T) -> dec2int(T).


%---------------------------------------------------------------------------------------------------------------
% This function converts binary to an integer.(e.g. <<35,46,34>> -> 2305570)
%---------------------------------------------------------------------------------------------------------------
bin2int(Binary) -> 
		BitSize = bit_size(Binary),
		<<Result:BitSize>> = Binary,
		Result.


%---------------------------------------------------------------------------------------------------------------
% Here this function parse one Magicline and returns parsed form in a tuple with their validities.
%---------------------------------------------------------------------------------------------------------------
parse(<<$# ,_/binary>>) -> [];
parse(<<$\n ,_/binary>>) -> [];
parse({_, {<<"indirect">>, _}, _, _}) -> [<<"indirect">>];
parse({{_,false},_,_,_}) -> [];
parse({_,{_,false},_,_}) -> [];
parse({_,_,{_,false},_}) -> [];

parse({{Offset,true},{Type,true},{Data,true},Result}) -> 
		[edit({Offset,Type,Data,Result})];
parse(Binary) -> 
		{Offset,ExOffset} = getOffset(Binary, <<>>),%essential line parsing start
		{Type ,ExType} = getType(ExOffset, <<>>) ,
		{Data ,ExData} = getData(ExType , <<>>) ,
		Result = getResult(ExData) ,
		parse({ {Offset,isValidOffset(Offset) },
		{Type ,isValidType(Type,<<>>) },
		{Data ,isValidData(Type,Data) },
		Result }).

%---------------------------------------------------------------------------------------------------------------
% getOffset reads Offset part from a magicline.
%---------------------------------------------------------------------------------------------------------------
getOffset(<<>> ,Offset) -> {Offset,<<>>};
getOffset(<<$\n, T/binary>> ,Offset) -> {Offset,T};
getOffset(<<$\s, T/binary>> ,Offset) -> {Offset,T};
getOffset(<<$\t, T/binary>> ,Offset) -> {Offset,T};
getOffset(<<Char,T/binary>> ,Offset) -> getOffset(T,<<Offset/binary,<<Char>>/binary>>).

%---------------------------------------------------------------------------------------------------------------
% Checks for validity of Offset
%---------------------------------------------------------------------------------------------------------------
isValidOffset(<<>> ) -> false;
isValidOffset(<<$> ,T/binary >> ) -> isValidOffset(T);
isValidOffset(<<$0,$x,T/binary >> ) -> isHex(T);
isValidOffset(T) -> isDec(T).


%---------------------------------------------------------------------------------------------------------------
% Reads Type part from a magicline.
%---------------------------------------------------------------------------------------------------------------
getType(<<$\s,T/binary>>,<<>>) -> getType(T,<<>>);
getType(<<$\t,T/binary>>,<<>>) -> getType(T,<<>>);
getType(<<>> ,Type) -> {Type,<<>>};
getType(<<$\n, T/binary>> ,Type) -> {Type,T};
getType(<<$\s, T/binary>> ,Type) -> {Type,T};
getType(<<$\t, T/binary>> ,Type) -> {Type,T};
getType(<<Char,T/binary>>,Type) -> getType(T,<<Type/binary,Char>>).

%---------------------------------------------------------------------------------------------------------------
% Checks for validity of Type
%---------------------------------------------------------------------------------------------------------------
isValidType(<<>>,<<>>) -> false;
isValidType(<<>>,Type) -> isValidType(Type);
isValidType(<<$&,$0,$x,T/binary>>,Type) -> isHex(T) and isValidType(Type);
isValidType(<<$&,T/binary>>,Type) -> isDec(T) and isValidType(Type);
isValidType(<<$/>>,<<"string">>) -> true;
isValidType(<<$/,T/binary>>,<<"string">>) -> isValidstr(<<$/,T/binary>>);
isValidType(<<Char,T/binary>>,Type) -> isValidType(T, <<Type/binary,Char>>).


isValidType(Type) -> 
	case Type of
		<<"short">> -> true;
		<<"beshort">> -> true;
		<<"leshort">> -> true;
		<<"long">> -> true;
		<<"belong">> -> true;
		<<"lelong">> -> true;
		<<"ubelong">> -> true;
		<<"byte">> -> true;
		<<"string">> -> true;
		<<"search", _/binary>> -> true;
		<<"regex", _/binary>> -> true;
		_Else -> false
	end.

%---------------------------------------------------------------------------------------------------------------
% Tests for "/[Bbc]*" part of string/[Bbc]* whether it is in the right form.
%---------------------------------------------------------------------------------------------------------------
isValidstr(<<$b>>) -> true;
isValidstr(<<$B>>) -> true;
isValidstr(<<$c>>) -> true;
isValidstr(<<$/>>) -> false;
isValidstr(<<"//" , _/binary>>) -> false;
isValidstr(<<Char, T/binary>>) when Char==$b ; Char==$B ; Char==$c ; Char==$/ -> isValidstr(T);
isValidstr(_) -> false.

%---------------------------------------------------------------------------------------------------------------
% Reads MagicData from a magicline.
%---------------------------------------------------------------------------------------------------------------
getData(<<$\s,T/binary>>,<<>>) -> getData(T,<<>>);
getData(<<$\t,T/binary>>,<<>>) -> getData(T,<<>>);
getData(<<>> ,Data) -> {Data,<<>>};
getData(<<$\n, T/binary>> ,Data) -> {Data,T};
getData(<<$\s, T/binary>> ,Data) -> {Data,T};
getData(<<$\t, T/binary>> ,Data) -> {Data,T};
getData(<<$\\,$\s,T/binary>>,Data) -> getData(T,<<Data/binary,<<$\s>>/binary>>);
getData(<<Char,T/binary>> ,Data) -> getData(T,<<Data/binary,<<Char>>/binary>>).


%---------------------------------------------------------------------------------------------------------------
% Controls whether Data is in the right form.
%---------------------------------------------------------------------------------------------------------------
isValidData(_,<<>>) -> false;
isValidData(<<"byte">>, <<"x">>) -> true;
isValidData(<<"search", _/binary>>, _) -> true;
isValidData(<<"regex", _/binary>>, _) -> true;
isValidData(Type,<<Op,T/binary>>) when 
		Op == $= ; Op == $! ; Op == $> ;
		Op == $< ; Op == $& ; Op == $^ -> 
			isValidData(Type,T,isValidType(Type,<<>>));
isValidData(Type,Data) -> 
		isValidData(Type,Data,isValidType(Type,<<>>)).


isValidData(_,_,false) -> false;
isValidData(<<"string",_/binary >>,_,true) -> true;
isValidData(_,<<$0,$x,T/binary>>,true) -> isHex(T);
isValidData(_,Data,true) -> isDec(Data).

%---------------------------------------------------------------------------------------------------------------
% Gets result part of Magicline.
%---------------------------------------------------------------------------------------------------------------
getResult(<<$\s , T/binary>>) -> getResult(T);
getResult(<<$\t , T/binary>>) -> getResult(T);
getResult(T) -> T.

%---------------------------------------------------------------------------------------------------------------
% Edits parsed line, it converts Offset,Type to integer and it fixes Data if it has speacial chars in it.(e.g.\021 octal ,\xa3 hex, \t,\a..)
%---------------------------------------------------------------------------------------------------------------
edit({Offset,Type,Data,Result}) -> { editOffset(Offset), editType(Type), editData(Type,Data), editResult(Result)}.

editOffset(T) -> editOffset(T , 0).
editOffset(<<"0">> , Level) -> {0,Level};
editOffset(<<">" ,T/binary>> , Level) -> editOffset(T , Level + 1);
editOffset(<<"0x" ,T/binary>> , Level) -> {hex2int(T) , Level};
editOffset(<<"0" ,T/binary>> , Level) -> {oct2int(T) , Level};
editOffset(T , Level) -> {dec2int(T) , Level}.


editResult(<<>>) -> <<>>;
editResult(<<"\\b",T/binary>>) -> editResult(T);
editResult(T) -> Size=size(T)-1, <<Result:Size/binary , Ch >> = T , editResult(Result, Ch).
editResult(Result, $\n) -> Result;
editResult(Result, Ch) -> <<Result/binary , Ch>>.


%---------------------------------------------------------------------------------------------------------------
% First we obtain head operator of MagicData then we edit main
% part of MagicData in editData1 function .e.g. for &0xae45df34 this operator is &.
%---------------------------------------------------------------------------------------------------------------
editData(Type,<<$=,Data/binary>> ) -> {$= , editData0(Type,Data)};
editData(Type,<<$!,Data/binary>> ) -> {$! , editData0(Type,Data)};
editData(Type,<<$>,Data/binary>> ) -> {$> , editData0(Type,Data)};
editData(Type,<<$<,Data/binary>> ) -> {$< , editData0(Type,Data)};
editData(Type,<<$&,Data/binary>> ) -> {$& , editData0(Type,Data)};
editData(Type,<<$^,Data/binary>> ) -> {$^ , editData0(Type,Data)};
editData(Type,Data ) -> {$= , editData0(Type,Data)}.

-define(STRING,<<"string",_/binary>>).
-define(SEARCH,<<"search", _/binary>>).
-define(REGEX, <<"regex", _/binary>>).

editData0(?REGEX, <<>>) -> <<>> ;
editData0(?REGEX, <<"\\a", T/binary>>) -> << 7 , (editData0(<<"search">>,T))/binary >> ; %Special chars from ascii e.g. \a,\n...
editData0(?REGEX, <<"\\b", T/binary>>) -> << $\b , (editData0(<<"search">>,T))/binary >> ;
editData0(?REGEX, <<"\\t", T/binary>>) -> << $\t , (editData0(<<"search">>,T))/binary >> ;
editData0(?REGEX, <<"\\n", T/binary>>) -> << $\n , (editData0(<<"search">>,T))/binary >> ;
editData0(?REGEX, <<"\\v", T/binary>>) -> << $\v , (editData0(<<"search">>,T))/binary >> ;
editData0(?REGEX, <<"\\f", T/binary>>) -> << $\f , (editData0(<<"search">>,T))/binary >> ;
editData0(?REGEX, <<"\\r", T/binary>>) -> << $\r , (editData0(<<"search">>,T))/binary >> ;
editData0(?REGEX, <<"\\x", T/binary>>) -> editData1(T) ; %We send Tail another editData which fixes hex strings
editData0(?REGEX, <<$\\,Char,T/binary>>) when Char>=$0 , Char =< $7 -> editData2((<<Char,T/binary>>)) ; %Fixing octal strings
editData0(?REGEX, <<$\\,Char,T/binary>>) -> << Char, (editData0(<<"search">>,T))/binary >> ;
editData0(?REGEX, <<Char ,T/binary>>) -> << Char, (editData0(<<"search">>,T))/binary >> ;


editData0(?SEARCH, <<>>) -> <<>> ;
editData0(?SEARCH, <<"\\a", T/binary>>) -> << 7 , (editData0(<<"search">>,T))/binary >> ; %Special chars from ascii e.g. \a,\n...
editData0(?SEARCH, <<"\\b", T/binary>>) -> << $\b , (editData0(<<"search">>,T))/binary >> ;
editData0(?SEARCH, <<"\\t", T/binary>>) -> << $\t , (editData0(<<"search">>,T))/binary >> ;
editData0(?SEARCH, <<"\\n", T/binary>>) -> << $\n , (editData0(<<"search">>,T))/binary >> ;
editData0(?SEARCH, <<"\\v", T/binary>>) -> << $\v , (editData0(<<"search">>,T))/binary >> ;
editData0(?SEARCH, <<"\\f", T/binary>>) -> << $\f , (editData0(<<"search">>,T))/binary >> ;
editData0(?SEARCH, <<"\\r", T/binary>>) -> << $\r , (editData0(<<"search">>,T))/binary >> ;
editData0(?SEARCH, <<"\\x", T/binary>>) -> editData1(T) ; %We send Tail another editData which fixes hex strings
editData0(?SEARCH, <<$\\,Char,T/binary>>) when Char>=$0 , Char =< $7 -> editData2((<<Char,T/binary>>)) ; %Fixing octal strings
editData0(?SEARCH, <<$\\,Char,T/binary>>) -> << Char, (editData0(<<"search">>,T))/binary >> ;
editData0(?SEARCH, <<Char ,T/binary>>) -> << Char, (editData0(<<"search">>,T))/binary >> ;

editData0(?STRING, <<>>) -> <<>> ;
editData0(?STRING, <<"\\a", T/binary>>) -> << 7 , (editData0(<<"string">>,T))/binary >> ; %Special chars from ascii e.g. \a,\n...
editData0(?STRING, <<"\\b", T/binary>>) -> << $\b , (editData0(<<"string">>,T))/binary >> ;
editData0(?STRING, <<"\\t", T/binary>>) -> << $\t , (editData0(<<"string">>,T))/binary >> ;
editData0(?STRING, <<"\\n", T/binary>>) -> << $\n , (editData0(<<"string">>,T))/binary >> ;
editData0(?STRING, <<"\\v", T/binary>>) -> << $\v , (editData0(<<"string">>,T))/binary >> ;
editData0(?STRING, <<"\\f", T/binary>>) -> << $\f , (editData0(<<"string">>,T))/binary >> ;
editData0(?STRING, <<"\\r", T/binary>>) -> << $\r , (editData0(<<"string">>,T))/binary >> ;
editData0(?STRING, <<"\\x", T/binary>>) -> editData1(T) ; %We send Tail another editData which fixes hex strings
editData0(?STRING, <<$\\,Char,T/binary>>) when Char>=$0 , Char =< $7 -> editData2((<<Char,T/binary>>)) ; %Fixing octal strings
editData0(?STRING, <<$\\,Char,T/binary>>) -> << Char, (editData0(<<"string">>,T))/binary >> ;
editData0(?STRING, <<Char ,T/binary>>) -> << Char, (editData0(<<"string">>,T))/binary >> ;

editData0(<<"byte">>, <<"x">>) -> <<"versionX">>;
editData0(Type , <<"0x" ,T/binary>>) -> <<(hdo2int(<<"0x" ,T/binary>>)):(mybitsize(Type))>>;
editData0(Type , <<"0" ,T/binary>>) -> <<(hdo2int(<<"0" ,T/binary>>)):(mybitsize(Type))>>;
editData0(Type , T ) -> <<(dec2int(T)):(mybitsize(Type))>>.


%---------------------------------------------------------------------------------------------------------------
% Conversions in hex should be like that, "\xpk" -> [$p,$k] , "\x10zs" -> [16,$z,$s] ,"\x103" -> [16,$3],
% "\xrs" -> [$x,$r.$s](since there is no hex digit)
%---------------------------------------------------------------------------------------------------------------
editData1(<<>>) -> <<$x>>;
editData1(<<Snd>> ) -> editData1({isHexDigit(Snd), Snd });
editData1({true ,Snd}) -> << (hex2int(<<Snd>>)) >>;
editData1({false,Snd}) -> << $x ,Snd>> ;
editData1(<<Fst,Snd,T/binary >> ) -> 
		editData1(isHexDigit(Fst),isHexDigit(Snd) , <<Fst,Snd>> , T).

editData1(true, true , Digits , T ) -> << << (hex2int(Digits)) >> /binary , (editData0(<<"string">>,T))/binary >> ;
editData1(true, false, <<Fst,Snd>>, T ) -> << << (hex2int(<<Fst>>)) >> /binary ,(editData0(<<"string">>,<<Snd,T/binary>>))/binary >> ;
editData1(false ,_ , Digits , T ) -> << $x ,(editData0(<<"string">>,<<Digits/binary,T/binary>>))/binary >> .

 
%---------------------------------------------------------------------------------------------------------------
% Conversions in octal is similar to conversions in hexadecimal e.g. "\10z" -> [8,$z]...
% After conversion if integer overflows byte, binary type automatically takes mod of number.e.g "\401" yields [1].
%---------------------------------------------------------------------------------------------------------------
editData2(<<Fst>>) -> <<(Fst-$0)>>;
editData2(<<Fst,Snd>>) -> editData2({isOctDigit(Snd), <<Fst,Snd>> });
editData2({true ,Digits}) -> << (oct2int(Digits)) >>;
editData2({false,<<Fst,Snd>> }) -> << (Fst-$0),Snd>> ;
editData2(<<Fst,Snd,Thrd,T/binary >>) -> editData2(isOctDigit(Snd),isOctDigit(Thrd) , <<Fst,Snd,Thrd>> , T).


editData2(true, true, Digits , T) -> << << (oct2int(Digits)) >> /binary , (editData0(<<"string">>,T))/binary >> ;
editData2(true, false, <<Fst,Snd,Thrd>>, T) -> << << (oct2int(<<Fst,Snd>>)) >> /binary ,(editData0(<<"string">>,<< Thrd,T/binary>>))/binary >> ;
editData2(false ,_, <<Fst,Snd,Thrd>>, T) -> << (Fst-$0) , (editData0(<<"string">>,<<Snd,Thrd,T/binary>>))/binary >> .

%---------------------------------------------------------------------------------------------------------------
% Some types takes additional parts like lelong&0xaf3d4523 or string/bC.In EditType functions we seperate them for convenience.
%---------------------------------------------------------------------------------------------------------------
editType( <<"string",$/, T/binary >> ) -> {string , binary_to_list(T)};
editType( <<"string">> ) -> {string , [] };
editType( <<"byte" >> ) -> {byte , novalue , little , 1};
editType( <<"short" >> ) -> {short , novalue , little , 2};
editType( <<"leshort">> ) -> {leshort, novalue , little , 2};
editType( <<"beshort">> ) -> {beshort, novalue , big , 2};
editType( <<"long" >> ) -> {long , novalue , little , 4};
editType( <<"lelong">> ) -> {lelong , novalue , little , 4};
editType( <<"ubelong">> ) -> {belong , novalue , big , 4};
editType( <<"belong">> ) -> {belong , novalue , big , 4};
editType( <<"byte" , $& , T/binary>> ) -> {byte , hdo2int(T) , little , 1};
editType( <<"short" , $& , T/binary>> ) -> {short , hdo2int(T) , little , 2};
editType( <<"leshort" , $& , T/binary>> ) -> {leshort, hdo2int(T) , little , 2};
editType( <<"beshort" , $& , T/binary>> ) -> {beshort, hdo2int(T) , big , 2};
editType( <<"long" , $& , T/binary>> ) -> {long , hdo2int(T) , little , 4};
editType( <<"lelong" , $& , T/binary>> ) -> {lelong , hdo2int(T) , little , 4};
editType( <<"ubelong" , $& , T/binary>> ) -> {belong , hdo2int(T) , big , 4};
editType( <<"belong" , $& , T/binary>> ) -> {belong , hdo2int(T) , big , 4};
editType( <<"search", T/binary>> ) -> {search , T};
editType( <<"regex", T/binary>>) -> {regex, T}.


%---------------------------------------------------------------------------------------------------------------
% This function returns the bit size of numeric types.
%---------------------------------------------------------------------------------------------------------------
mybitsize(<<"byte" ,_/binary>>) -> 8 ;
mybitsize(<<"short" ,_/binary>>) -> 16;
mybitsize(<<"long" ,_/binary>>) -> 32;
mybitsize(<<"leshort" ,_/binary>>) -> 16;
mybitsize(<<"lelong" ,_/binary>>) -> 32;
mybitsize(<<"beshort" ,_/binary>>) -> 16;
mybitsize(<<"ubelong" ,_/binary>>) -> 32;
mybitsize(<<"belong" ,_/binary>>) -> 32 .


%---------------------------------------------------------------------------------------------------------------
% Compare function test file for all Magiclines entirely.When it succeeds the test ends.
%---------------------------------------------------------------------------------------------------------------
-define(MYPARSE , [{{Offset , Level} , Type , Data , R } | Tail ] ).

compare(X) -> X.

compare(_,[]) -> <<"Unknown Type">>;

compare(FileData,?MYPARSE) when Level == 0 -> 
		compare(FileData , Tail , test(FileData,hd(?MYPARSE)));

compare(FileData,[_|T]) -> 
		compare(FileData , T ).
		
compare(FileData, Data , {ok , Result}) ->
		compare1(FileData , Data , true, 0 , Result);

compare(FileData, Data , error ) ->
		compare(FileData,Data).



compare1(_ , [] , _ , _ , Result) -> Result ;

compare1(FileData , ?MYPARSE , _, _ , <<>>) when Level == 0 -> compare(FileData , ?MYPARSE);

compare1(_ , [{{_ , 0}, _ , _ , _}|_] , _ , _ , Result ) -> Result ;

compare1( FileData , ?MYPARSE , false , OldLevel , Result) when Level < OldLevel + 1 ->
		compare2( FileData , Tail , Level, Result , test(FileData , hd(?MYPARSE)) );

compare1( FileData , ?MYPARSE , true , OldLevel , Result) when Level < OldLevel + 2 ->
		compare2( FileData , Tail , Level , Result , test(FileData , hd(?MYPARSE)));
                            
compare1( FileData , [_|T] , Bool , OldLevel , Result ) -> 
		compare1(FileData , T , Bool , OldLevel , Result).



compare2( FileData , Data , OldLevel , Result , {ok , Res} ) -> 
		compare1(FileData , Data , true , OldLevel , <<Result/binary ,$\s, Res/binary>>);

compare2( FileData , Data , OldLevel , Result , error ) ->
		compare1(FileData , Data , false , OldLevel , Result).

%---------------------------------------------------------------------------------------------------------------
% Tests for equality between MagicData and Target which got from FileData.
%---------------------------------------------------------------------------------------------------------------
test(FileData, {Offset, Type , {Op,Data}, Result}) -> 
		Target = getTarget( Offset, Type, Data, FileData),
		test(Target,{Op,Data},Type,Result).

test({ok,Target} , {$=, Data} , _ , Result) -> 
		result(Data == Target , Result);

test({ok,Target} , {$!, Data} , _ , Result) -> 
		result(Data /= Target , Result);

test({ok,Target} , {$>, Data} , _ , Result) -> 
		result(Data < Target , Result);

test({ok,Target} , {$<, Data} , _ , Result) -> 
		result(Data > Target , Result);

test({ok,Target} , {$&, Data} , Type , Result) -> 
		result( and_xor_test(Type,Data,Target,$&) , Result);

test({ok,Target} , {$^, Data} , Type , Result) -> 
		result( and_xor_test(Type,Data,Target,$^) , Result);

test({error,_ } , _ , _ , _ ) -> error.


and_xor_test({_,_,_,TypeSize},Data,Target,Operator) -> 
		NewTarget = bin2int(Target),
		NewData = bin2int(Data),
		TypebitSize=TypeSize*8,
		Result = bin2int (<<(NewTarget band NewData):TypebitSize>>),
		and_xor_test( Result == NewData , Operator ).

and_xor_test(true ,$&) -> true;
and_xor_test(false ,$^) -> true;
and_xor_test(_ ,_ ) -> false.


result(true , Result) -> {ok,Result};
result(false, _ ) -> error.

%---------------------------------------------------------------------------------------------------------------
% This function gets exact Data from FileData placed in offset with appropriate length.
%---------------------------------------------------------------------------------------------------------------
getTarget( Offset, {string , Flags } , Data, FileData) -> readString(FileData, Offset,Data,Flags);
getTarget( Offset, {_ , AndValue , Endianness , Size}, _ , FileData) -> 
		Target = readBin(FileData,Offset,Size,Endianness),
		readNumerics(Target , AndValue , Size).

readNumerics({ok,Target} , novalue , _ ) -> {ok,Target};
readNumerics({ok,Target} , AndValue , Size ) -> {ok,<<(AndValue band bin2int(Target)):Size/unit:8>>};
readNumerics({error,Reason} , _ , _ ) -> {error,Reason}.

%---------------------------------------------------------------------------------------------------------------
% Reads Number of bytes from a binary starting Offset with appropriate Endianness.
%---------------------------------------------------------------------------------------------------------------
readBin(Binary,{Offset , _},Number,Endiannes) -> readBin(Binary,Offset,Number,Endiannes, Offset + Number =< size(Binary) ).


readBin(Binary,Offset,Number,big ,true ) ->
		<<_:Offset/binary , Target:Number/big-unit:8 , _/binary>> = Binary , {ok,<<Target:Number/unit:8>>};

readBin(Binary,Offset,Number,little ,true ) ->
		<<_:Offset/binary , Target:Number/little-unit:8 , _/binary>> = Binary , {ok,<<Target:Number/unit:8>>};

readBin(Binary,Offset,Number,native ,true ) ->
		<<_:Offset/binary , Target:Number/native-unit:8 , _/binary>> = Binary , {ok,<<Target:Number/unit:8>>};

readBin(_ ,_ ,_ ,_ ,false) -> {error, "Binary does not have enough length to be read from Offset."}.


%---------------------------------------------------------------------------------------------------------------
% Reads string to be compared from target
%---------------------------------------------------------------------------------------------------------------
readString(FileData, Offset,Data,[]) -> readBin(FileData, Offset ,size(Data),big); %Read string if has no Flag.
readString(FileData, Offset,Data,Flags) -> Target = readBin(FileData, Offset ,size(Data)+20,big),
readString(Data ,Target,lists:member($b, Flags), lists:member($c, Flags), lists:member($B, Flags)).


readString(Data, {ok,Target}, true ,false, false) -> {ok,editFlag_b(Target, Data)};
readString(Data, {ok,Target}, true ,false, true ) -> {ok,editFlag_B(editFlag_b(Target, Data), Data)};
readString(Data, {ok,Target}, true ,true , false) -> {ok,editFlag_c(editFlag_b(Target , Data), Data)};
readString(Data, {ok,Target}, true ,true , true ) -> {ok,editFlag_B(editFlag_c(editFlag_b(Target , Data), Data), Data)};
readString(Data, {ok,Target}, false ,true , false) -> {ok,editFlag_c(Target, Data)};
readString(Data, {ok,Target}, false ,false, true ) -> {ok,editFlag_B(Target, Data)};
readString(Data, {ok,Target}, false ,true , true ) -> {ok,editFlag_c(editFlag_B(Target , Data), Data)};
readString(_ , {error,Reason},_ ,_ ,_ ) -> {error,Reason}.


%---------------------------------------------------------------------------------------------------------------
% Edits read string according to rules of Flag 'b'
%---------------------------------------------------------------------------------------------------------------
editFlag_b(_, <<>>) -> <<>>;
editFlag_b(<<$\s, T/binary>>, <<$\s, T1/binary>>) -> <<$\s, (editFlag_b(removeBlanks(T), T1))/binary>>;
editFlag_b(Target, <<$\s, T1/binary>>) -> <<$\s, (editFlag_b(Target, T1))/binary>>;
editFlag_b(<<H , T/binary>>, <<_ , T1/binary>>) -> <<H , (editFlag_b(T, T1))/binary>>.


%---------------------------------------------------------------------------------------------------------------
% editFlag_c(Target,Data):
% If a char is lowercase in Data, corresponding char in Target turns into lowecase if it is uppercase in Data it remains same in Target.
%---------------------------------------------------------------------------------------------------------------
editFlag_c(_ , <<>>) -> <<>>;
editFlag_c(<<H , T/binary >> , <<H1, T1/binary>> ) when H1 >= $a , H1 =< $z ,
                 H >= $A , H =< $Z ->
                 <<(H bor H1) , (editFlag_c(T,T1))/binary>>;
editFlag_c(<<H , T/binary >> , <<_ , T1/binary>> ) -> <<H, (editFlag_c(T,T1))/binary>>.

%---------------------------------------------------------------------------------------------------------------
% Edits read string according to rules of Flag 'B' .
%---------------------------------------------------------------------------------------------------------------
editFlag_B(_, <<>>) -> <<>>;
editFlag_B(<<>>, _) -> <<>>;
editFlag_B(<<$\s, T/binary>>, <<$\s, T1/binary>>) -> <<$\s , (editFlag_B(removeBlanks(T), T1))/binary>>;
editFlag_B(<<H , T/binary>>, <<_ , T1/binary>>) -> <<H, (editFlag_B(T, T1))/binary >>.

%---------------------------------------------------------------------------------------------------------------
% Removes initial blanks.
%---------------------------------------------------------------------------------------------------------------
removeBlanks(<<$\s, T/binary>>) -> removeBlanks(T);
removeBlanks(Target) -> Target.

%---------------------------------------------------------------------------------------------------------------
% Test Begins
% Find out the mime-types of the files in "TestFolder"
% and compares the results with the results of "file --mime-type" command
% Displays the different results as {index of file, "program's result", "command's result"}
% If the program's result and command's result are same, then the function doesn't display that file's result
%---------------------------------------------------------------------------------------------------------------
check() -> testModule(?TESTFOLDER).

%---------------------------------------------------------------------------------------------------------------
% Same as check() but this function gets the name of the folder to be tested as argument
%---------------------------------------------------------------------------------------------------------------
testModule(TestFolder) ->
		FileList = getFileNames(TestFolder),
		ErlRes = getErlResults(TestFolder, FileList, []),
		MimeRes = mimeTypeResults(TestFolder, FileList, []),
		Dif = compareResults(ErlRes, MimeRes, 1, []),
		if 
			Dif == [] ->
				erlang:display(FileList),
				"Test is passed.";
			true ->
				findDifFiles(Dif, FileList, [])
		end.

getFileNames(TestFolder) -> 
		{ok, FileList} = file:list_dir(TestFolder),
		FileList.

getErlResults(TestFolder, Files, Res) ->
		if 
			Files == [] -> 
				Res;
			true -> 
				getErlResults(TestFolder, tl(Files), Res ++ [getMimeType(TestFolder ++ "/" ++ hd(Files))] )
		end.
		
mimeTypeResults(TestFolder, Files, Res) ->
		if 
			Files == [] ->
				Res;
			true ->
				mimeTypeResults(TestFolder, tl(Files), Res ++ [command(TestFolder ++ "/" ++ hd(Files))] )
		end.
		
command(FileName) ->
		R = run("file --mime-type " ++ FileName),
		L = string:len(FileName),
		Lr = string:len(R),
		string:substr(R, L+3, Lr-L-3).						

compareResults(List1, List2, Index, Fails) ->
		if 
			(List1 == []) or (List2 == []) ->
				Fails;
			hd(List1) /= hd(List2) ->
				compareResults(tl(List1), tl(List2), Index +1, Fails ++ [{Index, hd(List1), hd(List2)}]);
			true ->
				compareResults(tl(List1), tl(List2), Index +1, Fails)
		end.

findDifFiles(DifList, FileList, Acc) ->
		{Num, Dif1, Dif2} = hd(DifList),
		Name = getFileName(FileList, Num),
		NewAcc = Acc ++ [{Num, Name, Dif1, Dif2}],		
		if 
			tl(DifList) == [] ->
				erlang:display(NewAcc);
			true ->
				findDifFiles(tl(DifList), FileList, NewAcc)
		end.

getFileName(FileList, Index) ->
		if 
			FileList == [] ->
				"";
			Index == 1 ->
				hd(FileList);
			true ->
				getFileName(tl(FileList), Index -1)
		end.


%---------------------------------------------------------------------------------------------------------------
% Command shell functions
%---------------------------------------------------------------------------------------------------------------
run(Cmd) ->
	run(Cmd, 5000).

run(Cmd, Timeout) ->
	Port = erlang:open_port({spawn, Cmd},[exit_status]),
	loop(Port,[], Timeout).

loop(Port, Data, Timeout) ->
	receive
		{Port, {data, NewData}} -> loop(Port, Data++NewData, Timeout);
		{Port, {exit_status, 0}} -> Data;
		{Port, {exit_status, S}} -> throw({commandfailed, S})
	after Timeout ->
		throw(timeout)
	end.
%---------------------------------------------------------------------------------------------------------------
