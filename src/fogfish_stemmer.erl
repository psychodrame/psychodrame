%%
%%   Copyright (c) 2013, Dmitry Kolesnikov
%%   All Rights Reserved.
%%
%%   Licensed under the Apache License, Version 2.0 (the "License");
%%   you may not use this file except in compliance with the License.
%%   You may obtain a copy of the License at
%%
%%       http://www.apache.org/licenses/LICENSE-2.0
%%
%%   Unless required by applicable law or agreed to in writing, software
%%   distributed under the License is distributed on an "AS IS" BASIS,
%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%   See the License for the specific language governing permissions and
%%   limitations under the License.
%%
%% @description
%%   Porter Stemmer Algorithm
%%   http://tartarus.org/~martin/PorterStemmer/def.txt
-module(fogfish_stemmer).

-export([
	word/1,
	measure/1
]).

%%
%% stem word
-spec(word/1 :: (list() | binary()) -> list() | binary()).

word(Word)
 when is_binary(Word), byte_size(Word) > 2 ->
 	rules5(
	 	rules4(
	 		rules3(
	 			rules2(
	 				rules1(Word)
	 			)
	 		)
	 	)
	);

word(Word)
 when is_binary(Word)  ->
   Word;

word(Word)
 when is_atom(Word) ->
 	word(atom_to_binary(Word, utf8));

word(Word)
 when is_list(Word) ->
 	word(list_to_binary(Word)).


%% Step 1a
%%     SSES -> SS                         caresses  ->  caress
%%     IES  -> I                          ponies    ->  poni
%%                                        ties      ->  ti
%%     SS   -> SS                         caress    ->  caress
%%     S    ->                            cats      ->  cat
rules1a(Word) ->
	case byte_size(Word) of
		Len when Len >= 4 -> 
			rules1a(binary:part(Word, Len, -4), Len, Word);
		Len when Len >  1 -> 
			rules1a(binary:part(Word, Len, -2), Len, Word);
		_ -> 
			Word
	end.

rules1a(<<$s, $s, $e, $s>>, Len, X) -> binary:part(X, 0, Len - 2);
rules1a(<<_,  $i, $e, $s>>, Len, X) -> binary:part(X, 0, Len - 2);
rules1a(<<_,  _,  $s, $s>>,_Len, X) -> X;
rules1a(<<_,  _,  _,  $s>>, Len, X) -> binary:part(X, 0, Len - 1);

rules1a(<<$s, $s>>,_Len, X) -> X;
rules1a(<<_,  $s>>, Len, X) -> binary:part(X, 0, Len - 1);

rules1a(_, _Len, X) ->
	X.


%% Step 1b
%%     (m>0) EED -> EE                    feed      ->  feed
%%                                        agreed    ->  agree
%%     (*v*) ED  ->                       plastered ->  plaster
%%                                        bled      ->  bled
%%     (*v*) ING ->                       motoring  ->  motor
%%                                        sing      ->  sing
rules1b(Word) ->
	case byte_size(Word) of
		Len when Len >= 4 -> 
			rules1b(binary:part(Word, Len, -4), Len, Word);
		_ -> 
			Word
	end.

rules1b(<<_, $e, $e, $d>>, Len, X) ->
	case measure(X, Len - 3) of
		0 -> 
			X;
		_ -> 
			binary:part(X, 0, Len - 1)
	end;

rules1b(<<_, _, $e, $d>>, Len, X) ->
	case '*v*'(X, Len - 2) of
		true  -> 
			rules1bb(binary:part(X, Len - 4, 2), Len - 2, binary:part(X, 0, Len - 2));
		false -> 
			X
	end;

% the rule is not applicable for short word
% rules1(<<$e, $d>>, Len, X) ->
% 	case '*v*'(X, Len - 2) of
% 		true  -> rules1b(binary:part(X, Len - 3, 2), Len - 2, binary:part(X, 0, Len - 2));
% 		false -> X
% 	end;

rules1b(<<_, $i, $n, $g>>, Len, X)
 when Len >= 5 ->
	case '*v*'(X, Len - 3) of
		true  -> 
			rules1bb(binary:part(X, Len - 5, 2), Len - 3, binary:part(X, 0, Len - 3));
		false -> 
			X
	end;

rules1b(_, _Len, X) ->
	X.


%% Step 1c
%%     (*v*) Y -> I                    happy        ->  happi
%%                                     sky          ->  sky
rules1c(Word) ->
	case byte_size(Word) of
		Len when Len >= 4 -> 
			rules1c(binary:part(Word, Len, -4), Len, Word);
		Len when Len >  1 -> 
			rules1c(binary:part(Word, Len, -2), Len, Word);
		_  ->
			Word
	end.

rules1c(<<_, _, _, $y>>, Len, X) ->
	case '*v*'(X, Len - 1) of
		true  -> 
			<<(binary:part(X, 0, Len - 1))/binary, $i>>;
		false -> 
			X
	end;

rules1c(<<_, $y>>, Len, X) ->
	case '*v*'(X, Len - 1) of
		true  -> 
			<<(binary:part(X, 0, Len - 1))/binary, $i>>;
		false -> 
			X
	end;

rules1c(_, _Len, X) ->
	X.

%% If the second or third of the rules in Step 1b is successful, the following
%% is done:

%%     AT -> ATE                       conflat(ed)  ->  conflate
%%     BL -> BLE                       troubl(ed)   ->  trouble
%%     IZ -> IZE                       siz(ed)      ->  size
%%     (*d and not (*L or *S or *Z))
%%        -> single letter
%%                                     hopp(ing)    ->  hop
%%                                     tann(ed)     ->  tan
%%                                     fall(ing)    ->  fall
%%                                     hiss(ing)    ->  hiss
%%                                     fizz(ed)     ->  fizz
%%     (m=1 and *o) -> E               fail(ing)    ->  fail
%%                                     fil(ing)     ->  file
rules1bb(<<$a, $t>>,_Len, X) -> <<X/binary, $e>>;
rules1bb(<<$b, $l>>,_Len, X) -> <<X/binary, $e>>;
rules1bb(<<$i, $z>>,_Len, X) -> <<X/binary, $e>>;
rules1bb(<<$l, $l>>,_Len, X) -> X;
rules1bb(<<$s, $s>>,_Len, X) -> X;
rules1bb(<<$z, $z>>,_Len, X) -> X;
rules1bb(<< C,  C>>, Len, X) ->
	case not is_vowel(X, false) of
		true  -> binary:part(X, 0, Len - 1);
		false -> X
	end;
rules1bb(_, Len, X) ->
	case (measure(X, Len) =:= 1) and ('*o'(X, Len)) of
		true  -> <<X/binary, $e>>;
		false -> X
	end.

rules1(X) ->
	rules1c(rules1b(rules1a(X))).


%% Step 2
%%
%%     (m>0) ATIONAL ->  ATE           relational     ->  relate
%%     (m>0) TIONAL  ->  TION          conditional    ->  condition
%%                                     rational       ->  rational
%%     (m>0) ENCI    ->  ENCE          valenci        ->  valence
%%     (m>0) ANCI    ->  ANCE          hesitanci      ->  hesitance
%%     (m>0) IZER    ->  IZE           digitizer      ->  digitize
%%     (m>0) ABLI    ->  ABLE          conformabli    ->  conformable
%%     (m>0) ALLI    ->  AL            radicalli      ->  radical
%%     (m>0) ENTLI   ->  ENT           differentli    ->  different
%%     (m>0) ELI     ->  E             vileli        - >  vile
%%     (m>0) OUSLI   ->  OUS           analogousli    ->  analogous
%%     (m>0) IZATION ->  IZE           vietnamization ->  vietnamize
%%     (m>0) ATION   ->  ATE           predication    ->  predicate
%%     (m>0) ATOR    ->  ATE           operator       ->  operate
%%     (m>0) ALISM   ->  AL            feudalism      ->  feudal
%%     (m>0) IVENESS ->  IVE           decisiveness   ->  decisive
%%     (m>0) FULNESS ->  FUL           hopefulness    ->  hopeful
%%     (m>0) OUSNESS ->  OUS           callousness    ->  callous
%%     (m>0) ALITI   ->  AL            formaliti      ->  formal
%%     (m>0) IVITI   ->  IVE           sensitiviti    ->  sensitive
%%     (m>0) BILITI  ->  BLE           sensibiliti    ->  sensible

%%
%%
rules2(Word) ->
	case byte_size(Word) of
		Len when Len >= 7 -> 
			rules2(binary:part(Word, Len, -7), Len, Word);
		Len when Len >= 4 -> 
			rules2(binary:part(Word, Len, -4), Len, Word);
		_                 -> Word
	end.

%%     (m>0) ATIONAL ->  ATE           relational     ->  relate
rules2(<<$a, $t, $i, $o, $n, $a, $l>>, Len, X) ->
	case measure(X, Len - 7) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 7))/binary, $a, $t, $e>>
	end;

%%     (m>0) TIONAL  ->  TION          conditional    ->  condition
rules2(<<_, $t, $i, $o, $n, $a, $l>>, Len, X) ->
	case measure(X, Len - 6) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 2)
	end;

%%     (m>0) ENCI    ->  ENCE          valenci        ->  valence
rules2(<<_, _, _, $e, $n, $c, $i>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 1))/binary, $e>>
	end;

%%     (m>0) ANCI    ->  ANCE          hesitanci      ->  hesitance
rules2(<<_, _, _, $a, $n, $c, $i>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 1))/binary, $e>>
	end;

%%     (m>0) IZER    ->  IZE           digitizer      ->  digitize
rules2(<<_, _, _, $i, $z, $e, $r>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 1)
	end;

%%     (m>0) ABLI    ->  ABLE          conformabli    ->  conformable
rules2(<<_, _, _, $a, $b, $l, $i>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 1))/binary, $e>>
	end;

%%     (m>0) ALLI    ->  AL            radicalli      ->  radical
rules2(<<_, _, _, $a, $l, $l, $i>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 2)
	end;

%%     (m>0) ENTLI   ->  ENT           differentli    ->  different
rules2(<<_, _, $e, $n, $t, $l, $i>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 2)
	end;

%%     (m>0) ELI     ->  E             vileli        - >  vile
rules2(<<_, _, _, _, $e, $l, $i>>, Len, X) ->
	case measure(X, Len - 3) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 2)
	end;
rules2(<<_, $e, $l, $i>>, Len, X) ->
	case measure(X, Len - 3) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 2)
	end;

%%     (m>0) OUSLI   ->  OUS           analogousli    ->  analogous
rules2(<<_, _, $o, $u, $s, $l, $i>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 2)
	end;

%%     (m>0) IZATION ->  IZE           vietnamization ->  vietnamize
rules2(<<$i, $z, $a, $t, $i, $o, $n>>, Len, X) ->
	case measure(X, Len - 7) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 5))/binary, $e>>
	end;

%%     (m>0) ATION   ->  ATE           predication    ->  predicate
rules2(<<_, _, $a, $t, $i, $o, $n>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 3))/binary, $e>>
	end;

%%     (m>0) ATOR    ->  ATE           operator       ->  operate
rules2(<<_, _, _, $a, $t, $o, $r>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 2))/binary, $e>>
	end;

%%     (m>0) ALISM   ->  AL            feudalism      ->  feudal
rules2(<<_, _, $a, $l, $i, $s, $m>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 3)
	end;

%%     (m>0) IVENESS ->  IVE           decisiveness   ->  decisive
rules2(<<$i, $v, $e, $n, $e, $s, $s>>, Len, X) ->
	case measure(X, Len - 7) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 4)
	end;

%%     (m>0) FULNESS ->  FUL           hopefulness    ->  hopeful
rules2(<<$f, $u, $l, $n, $e, $s, $s>>, Len, X) ->
	case measure(X, Len - 7) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 4)
	end;

%%     (m>0) OUSNESS ->  OUS           callousness    ->  callous
rules2(<<$o, $u, $s, $n, $e, $s, $s>>, Len, X) ->
	case measure(X, Len - 7) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 4)
	end;

%%     (m>0) ALITI   ->  AL            formaliti      ->  formal
rules2(<<_, _, $a, $l, $i, $t, $i>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 3)
	end;

%%     (m>0) IVITI   ->  IVE           sensitiviti    ->  sensitive
rules2(<<_, _, $i, $v, $i, $t, $i>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 3))/binary, $e>>
	end;

%%     (m>0) BILITI  ->  BLE           sensibiliti    ->  sensible
rules2(<<_, $b, $i, $l, $i, $t, $i>>, Len, X) ->
	case measure(X, Len - 6) of
		0 -> X;
		_ -> <<(binary:part(X, 0, Len - 5))/binary, $l, $e>>
	end;

rules2(_, _Len, X) ->
	X.

%% Step 3
%%
%%     (m>0) ICATE ->  IC              triplicate     ->  triplic
%%     (m>0) ATIVE ->                  formative      ->  form
%%     (m>0) ALIZE ->  AL              formalize      ->  formal
%%     (m>0) ICITI ->  IC              electriciti    ->  electric
%%     (m>0) ICAL  ->  IC              electrical     ->  electric
%%     (m>0) FUL   ->                  hopeful        ->  hope
%%     (m>0) NESS  ->                  goodness       ->  good

rules3(Word) ->
	case byte_size(Word) of
		Len when Len >= 5 -> 
			rules3(binary:part(Word, Len, -5), Len, Word);
		_ -> 
			Word
	end.

%%     (m>0) ICATE ->  IC              triplicate     ->  triplic
rules3(<<$i, $c, $a, $t, $e>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 3)
	end;

%%     (m>0) ATIVE ->                  formative      ->  form
rules3(<<$a, $t, $i, $v, $e>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 5)
	end;

%%     (m>0) ALIZE ->  AL              formalize      ->  formal
rules3(<<$a, $l, $i, $z, $e>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 3)
	end;

%%     (m>0) ICITI ->  IC              electriciti    ->  electric
rules3(<<$i, $c, $i, $t, $i>>, Len, X) ->
	case measure(X, Len - 5) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 3)
	end;

%%     (m>0) ICAL  ->  IC              electrical     ->  electric
rules3(<<_, $i, $c, $a, $l>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 2)
	end;

%%     (m>0) FUL   ->                  hopeful        ->  hope
rules3(<<_, _, $f, $u, $l>>, Len, X) ->
	case measure(X, Len - 3) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 3)
	end;

%%     (m>0) NESS  ->                  goodness       ->  good
rules3(<<_, $n, $e, $s, $s>>, Len, X) ->
	case measure(X, Len - 4) of
		0 -> X;
		_ -> binary:part(X, 0, Len - 4)
	end;

rules3(_, _Len, X) ->
	X.

%% Step 4
%%
%%     (m>1) AL    ->                  revival        ->  reviv
%%     (m>1) ANCE  ->                  allowance      ->  allow
%%     (m>1) ENCE  ->                  inference      ->  infer
%%     (m>1) ER    ->                  airliner       ->  airlin
%%     (m>1) IC    ->                  gyroscopic     ->  gyroscop
%%     (m>1) ABLE  ->                  adjustable     ->  adjust
%%     (m>1) IBLE  ->                  defensible     ->  defens
%%     (m>1) ANT   ->                  irritant       ->  irrit
%%     (m>1) EMENT ->                  replacement    ->  replac
%%     (m>1) MENT  ->                  adjustment     ->  adjust
%%     (m>1) ENT   ->                  dependent      ->  depend
%%     (m>1 and (*S or *T)) ION ->     adoption       ->  adopt
%%     (m>1) OU    ->                  homologou      ->  homolog
%%     (m>1) ISM   ->                  communism      ->  commun
%%     (m>1) ATE   ->                  activate       ->  activ
%%     (m>1) ITI   ->                  angulariti     ->  angular
%%     (m>1) OUS   ->                  homologous     ->  homolog
%%     (m>1) IVE   ->                  effective      ->  effect
%%     (m>1) IZE   ->                  bowdlerize     ->  bowdler

rules4(Word) ->
	case byte_size(Word) of
		Len when Len >= 5 -> 
			rules4(binary:part(Word, Len, -5), Len, Word);
		_ -> 
			Word
	end.

%%     (m>1) AL    ->                  revival        ->  reviv
rules4(<<_, _, _, $a, $l>>, Len, X) ->
	case measure(X, Len - 2) of
		M when M > 1 -> binary:part(X, 0, Len - 2);
		_            -> X
	end;

%%     (m>1) ANCE  ->                  allowance      ->  allow
rules4(<<_, $a, $n, $c, $e>>, Len, X) ->
	case measure(X, Len - 4) of
		M when M > 1 -> binary:part(X, 0, Len - 4);
		_            -> X
	end;

%%     (m>1) ENCE  ->                  inference      ->  infer
rules4(<<_, $e, $n, $c, $e>>, Len, X) ->
	case measure(X, Len - 4) of
		M when M > 1 -> binary:part(X, 0, Len - 4);
		_            -> X
	end;

%%     (m>1) ER    ->                  airliner       ->  airlin
rules4(<<_, _, _, $e, $r>>, Len, X) ->
	case measure(X, Len - 2) of
		M when M > 1 -> binary:part(X, 0, Len - 2);
		_            -> X
	end;

%%     (m>1) IC    ->                  gyroscopic     ->  gyroscop
rules4(<<_, _, _, $i, $c>>, Len, X) ->
	case measure(X, Len - 2) of
		M when M > 1 -> binary:part(X, 0, Len - 2);
		_            -> X
	end;

%%     (m>1) ABLE  ->                  adjustable     ->  adjust
rules4(<<_, $a, $b, $l, $e>>, Len, X) ->
	case measure(X, Len - 4) of
		M when M > 1 -> binary:part(X, 0, Len - 4);
		_            -> X
	end;

%%     (m>1) IBLE  ->                  defensible     ->  defens
rules4(<<_, $i, $b, $l, $e>>, Len, X) ->
	case measure(X, Len - 4) of
		M when M > 1 -> binary:part(X, 0, Len - 4);
		_            -> X
	end;

%%     (m>1) ANT   ->                  irritant       ->  irrit
rules4(<<_, _, $a, $n, $t>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1) EMENT ->                  replacement    ->  replac
rules4(<<$e, $m, $e, $n, $t>>, Len, X) ->
	case measure(X, Len - 5) of
		M when M > 1 -> binary:part(X, 0, Len - 5);
		_            -> X
	end;

%%     (m>1) MENT  ->                  adjustment     ->  adjust
rules4(<<_, $m, $e, $n, $t>>, Len, X) ->
	case measure(X, Len - 4) of
		M when M > 1 -> binary:part(X, 0, Len - 4);
		_            -> X
	end;

%%     (m>1) ENT   ->                  dependent      ->  depend
rules4(<<_, _, $e, $n, $t>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1 and (*S or *T)) ION ->     adoption       ->  adopt
rules4(<<_, $s, $i, $o, $n>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

rules4(<<_, $t, $i, $o, $n>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1) OU    ->                  homologou      ->  homolog
rules4(<<_, _, _, $o, $u>>, Len, X) ->
	case measure(X, Len - 2) of
		M when M > 1 -> binary:part(X, 0, Len - 2);
		_            -> X
	end;

%%     (m>1) ISM   ->                  communism      ->  commun
rules4(<<_, _, $i, $s, $m>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1) ATE   ->                  activate       ->  activ
rules4(<<_, _, $a, $t, $e>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1) ITI   ->                  angulariti     ->  angular
rules4(<<_, _, $i, $t, $i>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1) OUS   ->                  homologous     ->  homolog
rules4(<<_, _, $o, $u, $s>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1) IVE   ->                  effective      ->  effect
rules4(<<_, _, $i, $v, $e>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

%%     (m>1) IZE   ->                  bowdlerize     ->  bowdler
rules4(<<_, _, $i, $z, $e>>, Len, X) ->
	case measure(X, Len - 3) of
		M when M > 1 -> binary:part(X, 0, Len - 3);
		_            -> X
	end;

rules4(_, _Len, X) ->
	X.

%% Step 5a
%%
%%     (m>1) E     ->                  probate        ->  probat
%%                                     rate           ->  rate
%%     (m=1 and not *o) E ->           cease          ->  ceas
%%
rules5a(Word) ->
	case byte_size(Word) of
		Len when Len >= 4 -> 
			rules5a(binary:part(Word, Len, -2), Len, Word);
		_ -> 
			Word
	end.

rules5a(<<_, $e>>, Len, X) ->
	case measure(X, Len - 1) of
		M when M > 1 -> binary:part(X, 0, Len - 1);
		1            ->
			case not '*o'(X, Len - 1) of
				true  -> binary:part(X, 0, Len - 1);
				false -> X
			end;
		_            -> X
	end;

rules5a(_, _Len, X) ->
	X.


%% Step 5b
%%
%%     (m > 1 and *d and *L) -> single letter
%%                                     controll       ->  control
%%                                     roll           ->  roll
rules5b(Word) ->
	case byte_size(Word) of
		Len when Len >= 4 -> 
			rules5b(binary:part(Word, Len, -2), Len, Word);
		_                 -> 
			Word
	end.


rules5b(<<$l, $l>>, Len, X) ->
	case measure(X, Len) of
		M when M > 1 -> 
			binary:part(X, 0, Len - 1);
		_            -> 
			X
	end;

rules5b(_, _Len, X) ->
	X.

%%
%%
rules5(X) ->
	rules5b(rules5a(X)).

%%
%% [C](VC){m}[V].
%%    m  is called the measure of any word or word part when represented in
%%    this form. The case m = 0 covers the null word. Here are some examples:
%%
%%    m=0    TR, EE, TREE, Y, BY.
%%    m=1    TROUBLE, OATS, TREES, IVY.
%%    m=2    TROUBLES, PRIVATE, OATEN, ORRERY.
%%
%% A \consonant\ in a word is a letter other than A, E, I, O or U, and other
%% than Y preceded by a consonant.
measure(X)        ->
	measure(X, byte_size(X)).

measure(Seq, Len) ->
	case fold(fun do_measure/2, {consonant, -1}, 0, Len, Seq) of
		{consonant, M} -> M + 1;
		{vowel,     M} -> M
	end.

do_measure($a, {Type,  M}) -> {vowel, m(Type, M)};
do_measure($e, {Type,  M}) -> {vowel, m(Type, M)};
do_measure($i, {Type,  M}) -> {vowel, m(Type, M)};
do_measure($o, {Type,  M}) -> {vowel, m(Type, M)};
do_measure($u, {Type,  M}) -> {vowel, m(Type, M)};
do_measure($y, {consonant, M}) -> {vowel, M + 1};
do_measure($y, {vowel,     M}) -> {consonant, M};
do_measure(_,  {_Type, M}) -> {consonant, M}.

m(vowel,     M) -> M;
m(consonant, M) -> M + 1.

%% 
%% *v* - the stem contains a vowel.
'*v*'(Seq, Len) ->
	fold(fun is_vowel/2, false, 0, Len, Seq).

is_vowel(_, true) -> true;
is_vowel($a,   _) -> true;
is_vowel($e,   _) -> true;
is_vowel($i,   _) -> true;
is_vowel($o,   _) -> true;
is_vowel($u,   _) -> true;
is_vowel($y,   _) -> true;
is_vowel(_,    _) -> false.

%% *o  - the stem ends cvc, where the second c is not W, X or Y (e.g.
%%       -WIL, -HOP).
'*o'(Seq, Len)
 when size(Seq) >= 3 ->
	case binary:part(Seq, Len - 3, 3) of
		<<_, _, $w>> -> false;
		<<_, _, $x>> -> false;
		<<_, _, $y>> -> false;
		<<A, B,  C>> -> (not is_vowel(A, false)) and (is_vowel(B, false)) and (not is_vowel(C, false))
	end;

'*o'(_, _) ->
	false.

%% 
%% fold function over sequence of bytes
fold(Fun,  Acc, Pos, Len, Seq)
 when Pos < Len ->
	fold(Fun, Fun(binary:at(Seq, Pos), Acc), Pos + 1, Len, Seq);
fold(_Fun, Acc, _Pos, _Len, _Seq) ->
	Acc.




