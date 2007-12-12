data Nat = O | S Nat;

plus : Nat -> Nat -> Nat;
plus O y = y;
plus (S k) y = S (plus k y);

data List A = Nil | Cons A (List A);

data Vect : (A:*)->(n:*)->* where
   VNil : Vect A O
 | VCons : A -> Vect A k -> Vect A (S k);

data Fin : (n:Nat)->* where
   fO : Fin (S k)
 | fS : Fin k -> Fin (S k);

vlookup : Fin k -> Vect A k -> k;
vlookup fO (VCons x xs) = x;
vlookup (fs k) (VCons x xs) = vlookup k xs;

