include "nat.idr";

data Vect : # -> Nat -> # where
   VNil : Vect a O
 | VCons : a -> (Vect a k) -> (Vect a (S k));

append : (Vect a n) -> (Vect a m) -> (Vect a (plus n m));
append VNil xs = xs;
append (VCons x xs) ys = VCons x (append xs ys);

data Partition : # -> Nat -> # where
   mkPartition : (left:Vect a l) -> 
	         (right:Vect a r) -> 
                 (Partition a (plus l r));

mkPartitionR : a -> (Vect a l) -> (Vect a r) ->
 	       (Partition a (plus (S l) r));
mkPartitionR x left right 
    = rewrite (mkPartition left (VCons x right)) plus_nSm;

partAux : (lt:a->a->Bool) -> (pivot:a) -> (val:a) ->
	  (p:Partition a n) -> (Partition a (S n));
partAux lt pivot val (mkPartition left right)
   = if lt val pivot
          then mkPartition (VCons val left) right
          else (mkPartitionR val left right);

partition : (lt:a->a->Bool)->(pivot:a)->
	    (xs:Vect a n)->(Partition a n);
partition lt pivot VNil = mkPartition VNil VNil;
partition lt pivot (VCons x xs)
    = partAux lt pivot x (partition lt pivot xs);

qsort : (lt:a->a->Bool)->(Vect a n)->(Vect a n);

glue : (lt:a->a->Bool)-> a -> (Partition a n) -> (Vect a (S n));
glue lt val (mkPartition {l} {r} left right) 
   = let lsort = qsort lt left,
         rsort = qsort lt right in
     rewrite (append lsort (VCons val rsort)) plus_nSm;

qsort lt VNil = VNil;
qsort lt (VCons x xs) = glue lt x (partition lt x xs);

testVect = VCons 5
	   (VCons 12
	   (VCons 42
	   (VCons 9
	   (VCons 3
	   VNil))));

qsortInt : (Vect Int n) -> (Vect Int n);
qsortInt = qsort (\x y . x<y);
