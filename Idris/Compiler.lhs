> {-# OPTIONS_GHC -fglasgow-exts #-}

> module Idris.Compiler(comp) where

> import Idris.AbsSyntax
> import Idris.PMComp
> import Idris.LambdaLift
> import Ivor.TT

Get every definition from the context. Convert them all to simple case
trees. Ignore constructors, types, etc. Simple definitions are, of course, 
already simple case trees.

> comp :: Ctxt IvorFun -> Context -> Id -> FilePath -> IO ()
> comp raw ctxt nm ofile = do let pdefs = getAllPatternDefs ctxt
>                             let pcomp = map (pmCompDef raw ctxt) pdefs
>                             dumpComp pcomp
>                             putStrLn "Not implemented"
>    where dumpComp [] = return ()
>          dumpComp ((x,(args,def)):xs) 
>                       = do print x
>                            print (args, def)
>                            putStrLn "----------------------"
>                            let lifted = lambdaLift x args def
>                            dumpLift ctxt lifted
>                            putStrLn "======================"
>                            dumpComp xs


> dumpLift :: Context -> [(Name, [Name], SimpleCase)] -> IO ()
> dumpLift _ [] = return ()
> dumpLift ctxt ((n, args, def):xs) 
>              = do let def' = toSC ctxt def
>                   putStrLn $ "\t" ++ show n
>                   putStrLn $ "\t" ++ show (args,def')
>                   putStrLn "--------"
>                   dumpLift ctxt xs

> pmCompDef :: Ctxt IvorFun -> Context -> 
>              (Name, (ViewTerm, Patterns)) -> 
>              (Name, ([Name], SimpleCase))
> pmCompDef raw ctxt (n, (ty,ps)) = (n, pmcomp raw ctxt n ty ps)