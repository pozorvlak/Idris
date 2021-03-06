include "list.idr";

-- FAny is to allow C functions to build up Idris data
-- types. Obviously this needs care...

data FType = FUnit | FInt | FStr | FPtr | FAny Set
           | FIntP (Int -> Bool);

i_ftype : FType -> Set;
i_ftype FInt = Int;
i_ftype FStr = String;
i_ftype FPtr = Ptr;
i_ftype FUnit = ();
i_ftype (FAny ty) = ty;
i_ftype (FIntP p) = (x : Int ** so (p x)); 

data ForeignFun = FFun String (List FType) FType;

f_retType : ForeignFun -> FType;
f_retType (FFun nm args ret) = ret;

f_args : ForeignFun -> (List FType);
f_args (FFun nm args ret) = args;

f_name : ForeignFun -> String;
f_name (FFun nm args ret) = nm;

data FArgList : (List FType) -> Set where
    fNil : FArgList Nil
  | fCons : {x:FType} -> (fx:i_ftype x) -> (fxs:FArgList xs) ->
			 (FArgList (Cons x xs));

fapp : {xs,ys:List FType} -> 
       (FArgList xs) -> (FArgList ys) -> (FArgList (app xs ys));
fapp fNil fxs = fxs;
fapp (fCons fx fxs) fys = fCons fx (fapp fxs fys);

namespace IO {

  data IO : Set -> Set;

  data Command : Set where
      PutStr : String -> Command
    | GetStr : Command
    | Fork : {A:Set} -> A -> Command
    | NewLock : Int -> Command
    | DoLock : Lock -> Command
    | DoUnlock : Lock -> Command
    | NewRef : Command
    | ReadRef : Set -> Int -> Command
    | WriteRef : {A:Set} -> Int -> A -> Command
    | While : (IO Bool) -> (IO ()) -> Command
    | WhileAcc : {A:Set} -> (IO Bool) -> A -> (A -> IO A) -> Command
    | Within : Int -> (IO A) -> (IO A) -> Command
    | IOLift : {A:Set} -> (IO A) -> Command 
    | Foreign : (f:ForeignFun) -> 
  	        (args:FArgList (f_args f)) -> Command;

  Response : Command -> Set;
  Response (PutStr s) = ();
  Response GetStr = String;
  Response (Fork proc) = ();
  Response (NewLock i) = Lock;
  Response (DoLock l) = ();
  Response (DoUnlock l) = ();
  Response NewRef = Int;
  Response (ReadRef A i) = A;
  Response (WriteRef i val) = ();
  Response (While _ body) = ();
  Response (WhileAcc {A} _ acc body) = A;
  Response (Within {A} time body failure) = A;
  Response (IOLift {A} f) = A;
  Response (Foreign t args) = i_ftype (f_retType t);


  data IO : Set -> Set where
     IOReturn : A -> (IO A)
   | IODo : (c:Command) -> ((Response c) -> (IO A)) -> (IO A);

  data IORef A = MkIORef Int;

  bind : (IO a) -> (a -> (IO b)) -> (IO b);
  bind (IOReturn a) k = k a;
  -- bind (IODo (IOLift {A} c) p) k = bind (bind c p) k;
  bind (IODo c p) k = IODo c (\y => (bind (p y) k));
  -- bind (IOError str) k = IOError str;

  ret : a -> IO a;
  ret x = IOReturn x;
}

kbind : (IO a) -> (a -> b) -> (IO b);
kbind (IOReturn a) k = IOReturn (k a);
kbind (IODo c p) k = IODo c (\x => (kbind (p x) k));

while : |(test:IO Bool) -> |(body: IO ()) -> IO ();
while t body = IODo (While t body) (\a => (IOReturn II));

while_accTR : Bool -> 
            |(test:IO Bool) -> acc -> |(body: acc -> IO acc) -> IO acc;

while_acc : |(test:IO Bool) -> acc -> |(body: acc -> IO acc) -> IO acc;
{-
while_acc test acc body = do { test' <- test;
	       	   	       while_accTR test' test acc body; };

while_accTR True test acc body = do { acc' <- body acc;
	    	      	       	      test' <- test;
	       	       	              while_accTR test' test acc' body; };
while_accTR False test acc body = return acc;
-}
while_acc test acc body = IODo (WhileAcc test acc body) (\a => (IOReturn a));

{-
ioReturn : a -> (IO a);
ioReturn x = IOReturn x;
-}

apply : IO (a -> b) -> IO a -> IO b;
apply {a} {b} fn arg = do { f : (a->b) <- fn; -- grr
                            x <- arg;
              		    return (f x); };

data IOException = IOExcept String; 

data IOe : Set -> Set where
   IOK : (IO A) -> (IOe A)
 | IOError : String -> (IOe A);

{-
catch : (IOe A) -> (IOException -> (IO A)) -> (IO A);
catch (IOK action) = action;
catch (IOError str) handler = handler (IOExcept str);
-}

-- No code for this - only works in compiled code, certainly shouldn't
-- be evaluted in pure code!
unsafePerformIO : (IO A) -> A;

-- get the rts representation of a value
unsafeNative : A -> Ptr;

putStr : String -> (IO ());
putStr str = IODo (PutStr str) (\a => (IOReturn a));

getStr : IO String;
getStr = IODo GetStr (\b => (IOReturn b));

getInt : IO Int;
getInt = do { inp <- getStr;
              let val = __toInt inp;
	      return val; };

putStrLn : String -> (IO ());
putStrLn str = do { putStr str;
		    putStr "\n"; };

fork : |(proc:IO ()) -> (IO ());
fork proc = IODo (Fork proc) (\a => (IOReturn a));

newLock : Int -> (IO Lock);
newLock i = IODo (NewLock i) (\l => (IOReturn l));

lock : Lock -> (IO ());
lock l = IODo (DoLock l) (\a => (IOReturn a));

unlock : Lock -> (IO ());
unlock l = IODo (DoUnlock l) (\a => (IOReturn a));

-- Perform an action within "time" milliseconds, execute failure
-- routine if it doesn't complete

within : Int -> |(action : IO a) -> |(failure : IO a) -> IO a;
within time act fail = IODo (Within time act fail) (\a => (IOReturn a));

newIORefPrim : IO Int;
newIORefPrim = IODo (NewRef) (\i => (IOReturn i));

readIORefPrim : Int -> (IO A);
readIORefPrim {A} i = IODo (ReadRef A i) (\a => (IOReturn a));

writeIORefPrim : Int -> A -> (IO ());
writeIORefPrim {A} i val = IODo (WriteRef {A} i val) (\a => (IOReturn a));

newIORef : A -> (IO (IORef A));
newIORef val = do { i <- newIORefPrim;
		    writeIORefPrim i val;
		    return (MkIORef i);
		  };

readIORef : (IORef A) -> (IO A);
readIORef (MkIORef i) = readIORefPrim i;

writeIORef : (IORef A) -> A -> (IO ());
writeIORef (MkIORef i) val = writeIORefPrim i val;

mkFType' : (List FType) -> FType -> Set  ; [%nocg]

mkFType' Nil rt = IO (i_ftype rt);
mkFType' (Cons t ts) rt = (i_ftype t) -> (mkFType' ts rt);

mkFType : ForeignFun -> Set   ; [%nocg]
mkFType (FFun fn args rt) = mkFType' args rt;

mkFDef : String -> (ts:List FType) -> (xs:List FType) -> (FArgList xs) ->
	 (rt:FType) -> (mkFType' ts rt)  ; [%nocg]
mkFDef nm Nil accA fs rt 
   = IODo (Foreign (FFun nm accA rt) fs)
				 (\a => (IOReturn a));
mkFDef nm (Cons t ts) accA fs rt 
   = \x:i_ftype t => mkFDef nm ts (app accA (Cons t Nil)) 
				   (fapp fs (fCons x fNil)) rt;

mkForeign : (f:ForeignFun) -> (mkFType f)  ; [%nocg]
mkForeign (FFun fn args rt) = mkFDef fn args Nil fNil rt;

_isNull = mkForeign (FFun "isNull" (Cons FPtr Nil) FInt); [%eval]

isNull : Ptr -> Bool;
isNull ptr = if_then_else ((unsafePerformIO (_isNull ptr))==0) False True;

data File = FHandle Ptr;

_fopen
  = mkForeign (FFun "fileOpen" (Cons FStr (Cons FStr Nil)) FPtr); [%eval]
_fclose 
  = mkForeign (FFun "fileClose" (Cons FPtr Nil) FUnit); [%eval]
_fread
  = mkForeign (FFun "freadStr" (Cons FPtr Nil) (FAny String)); [%eval]
_fwrite
  = mkForeign (FFun "fputStr" (Cons FPtr (Cons FStr Nil)) FUnit); [%eval]
_feof
  = mkForeign (FFun "feof" (Cons FPtr Nil) FInt); [%eval]

gc_details
  = mkForeign (FFun "epicMemInfo" Nil FUnit); [%eval]

gc_collect
  = mkForeign (FFun "epicGC" Nil FUnit); [%eval]

fopen : String -> String -> IO File;
fopen str mode = do { ho <- _fopen str mode;
		      return (FHandle ho); };

fclose : File -> IO ();
fclose (FHandle h) = _fclose h;

fread : File -> IO String;
fread (FHandle hn) = _fread hn;

fwrite : File -> String -> IO ();
fwrite (FHandle h) str = _fwrite h str;

feof : File -> IO Bool;
feof (FHandle h) = do { eof <- _feof h;
     	      	      	return (not (eof==0)); };

sequence : (List (IO a)) -> (IO (List a));
sequence Nil = return Nil;
sequence (Cons x xs) = do { a <- x;
			    as <- sequence xs;
			    return (Cons a as); };

sleep = mkForeign (FFun "sleep" (Cons FInt Nil) FUnit); [%eval]

-- Return time in microseconds since some unspecified starting point

utime = mkForeign (FFun "do_utime" Nil FInt); [%eval]
