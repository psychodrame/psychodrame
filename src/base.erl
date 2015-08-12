%% This is taken from Flake

-module (base).

-export ([
	  as_list/2
	 ]).


%% @spec integer_to_list(Integer :: integer(), Base :: integer()) ->
%%          string()
%% @doc Convert an integer to its string representation in the given
%%      base.  Bases 2-62 are supported.
as_list(I, 10) ->
    erlang:integer_to_list(I);
as_list(I, Base)
  when is_integer(I),
       is_integer(Base),
       Base >= 2,
       Base =< 1+$Z-$A+10+1+$z-$a ->
  if
      I < 0 ->
	  [$-|as_list(-I, Base, [])];
      true ->
	  as_list(I, Base, [])
  end;
as_list(I, Base) ->
    erlang:error(badarg, [I, Base]).

%% @spec integer_to_list(integer(), integer(), stringing()) -> string()
as_list(I0, Base, R0) ->
    D = I0 rem Base,
    I1 = I0 div Base,
    R1 =
	if
	    D >= 36 ->
		[D-36+$a|R0];
	    D >= 10 ->
		[D-10+$A|R0];
	    true ->
		[D+$0|R0]
	end,
    if
      I1 =:= 0 ->
	    R1;
	true ->
	    as_list(I1, Base, R1)
    end.

