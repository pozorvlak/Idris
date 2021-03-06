data List a = Nil | Cons a (List a);

map : (a->b) -> (List a) -> (List b);
map f Nil = Nil;
map f (Cons x xs) = Cons (f x) (map f xs);

consp : Bool -> a -> (List a) -> (List a);
consp True x xs = Cons x xs;
consp False x xs = xs;

filter : (a->Bool) -> (List a) -> (List a);
filter p Nil = Nil;
filter p (Cons x xs) = consp (p x) x (filter p xs);

maybeCons : (Maybe a) -> (List a) -> (List a);
maybeCons Nothing xs = xs;
maybeCons (Just a) xs = (Cons a xs);

mapMaybe : (a->(Maybe b)) -> (List a) -> (List b);
mapMaybe f Nil = Nil;
mapMaybe f (Cons x xs) = maybeCons (f x) (mapMaybe f xs);

app : (List a) -> (List a) -> (List a);
app Nil xs = xs;
app (Cons x xs) ys = Cons x (app xs ys);

foldl : (a -> b -> a) -> a -> (List b) -> a;
foldl f z Nil = z;
foldl f z (Cons x xs) = foldl f (f z x) xs;

foldr : (a -> b -> b) -> b -> (List a) -> b;
foldr f z Nil = z;
foldr f z (Cons x xs) = f x (foldr f z xs);

rev : (List a) -> (List a);
rev xs = foldl (flip Cons) Nil xs;

eq_resp_Cons : {xs,ys:List A} -> (xs=ys) -> ((Cons x xs) = (Cons x ys));
eq_resp_Cons {A} {x} (refl xs) = refl _;

elem : (a->a->Bool) -> a -> (List a) -> Bool;
elem q x Nil = False;
elem q x (Cons y ys) = if_then_else (q x y) True (elem q x ys);

app_assoc : (xs:List a) -> (ys:List a) -> (zs:List a) ->
	    (app xs (app ys zs) = app (app xs ys) zs);

app_assoc Nil ys zs = refl _;
app_assoc (Cons x xs) ys zs = let rec = app_assoc xs ys zs in
	  	      	      ?app_assocCons;
app_assocCons proof {
	%intro;
	%rewrite rec;
	%refl;
	%qed;
};

app_Nil : (xs:List a) -> (app xs Nil = xs);
app_Nil Nil = refl _;
app_Nil (Cons x xs) = ?appNil_Cons;
appNil_Cons proof {
	%intro a;
	%intro;
	%rewrite <- app_Nil xs;
	%refl;
	%qed;
};

span' : (a -> Bool) -> List a -> List a -> (List a & List a);
span' p Nil acc         = (rev acc, Nil);
span' p (Cons x xs) acc = if (p x) then (span' p xs (Cons x acc))
      	      	      	           else (rev acc, Cons x xs);

span : (a -> Bool) -> List a -> (List a & List a);
span p xs = span' p xs Nil;
