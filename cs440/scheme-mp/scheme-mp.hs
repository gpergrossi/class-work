{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

import Text.ParserCombinators.Parsec

data Exp = IntExp Integer
         | SymExp String
         | SExp [Exp]
         deriving (Show)

data Val = IntVal Integer
         | SymVal String
         | PrimVal ([Val] -> Val)
         | Closure [String] Exp [(String, Val)]
         | DefVal String Val

run x = parseTest x


-- Lexicals

adigit = oneOf ['0'..'9']
digits = many1 adigit
symbol = oneOf "-*+/:'?><="


-- Grammaticals

anInt = do d <- digits
           return $ IntExp (read d)

anAtom = anInt

aSymbol = do first <- symbol <|> letter
             more  <- many (symbol <|> letter <|> digit)
             return $ SymExp (first:more)


aList = do char '('
           skipMany space
           res <- sepBy anExp (skipMany1 space)
           char ')'
           return $ SExp res

anExp = anAtom <|> aSymbol <|> aList


-- Evaluator

eval :: Exp -> [(String,Val)] -> Val
eval (IntExp i) env = IntVal i
eval (SymExp s) env = case entry of
    Just x -> x
    Nothing -> error $ "Undefined symbol '" ++ s ++ "'"
  where entry = lookup s env

eval (SExp []) env = SymVal "nil"

eval (SExp ((SymExp "def"):xs)) env = case xs of
    (SymExp var):body:[] -> DefVal var (eval body env)
    _ -> error "def expects a variable name and a value"

eval (SExp ((SymExp "define"):xs)) env = case xs of
    (SymExp fn):(SExp args):body:[] -> DefVal fn c
        where exps xx = map (\(SymExp y) -> y) xx
              cenv = (fn, c):env
              c = Closure (exps args) body cenv
    otherwise -> error $ "define expects a function name, a list of args, and a body"

eval (SExp (x:xs)) env = case (eval x env) of
    (PrimVal f) -> f $ map (\y -> eval y env) xs
    (Closure cargs exp cenv) -> eval exp fullenv
        where fullenv = zip cargs args ++ cenv
              args = map (\y -> eval y env) xs


-- Printer

instance Show Val where
  show (IntVal i) = show i
  show (SymVal s) = s
  show (DefVal s _) = s
  show (Closure _ _ _) = "closure"

repl defs =
  do putStr "> "
     l <- getLine
     case parse anExp "Expression" l of
       Right exp -> do
           putStr (show evl)
           putStrLn ""
           repl nudefs
         where evl = (eval exp defs)
               nudefs = case evl of
                 (DefVal name val) -> (name,val):defs
                 otherwise -> defs
       Left pe -> do
           putStr (show pe)
           putStrLn ""
           repl defs

main = repl runtime


-- Definitions

liftIntOp f a = PrimVal func
    where vals xx = map (\(IntVal x) -> x) xx
          func xx = IntVal $ foldr f a (vals xx)


-- Runtime

runtime = 
  [
    (   "+",    liftIntOp (+) 0     ),
    (   "*",    liftIntOp (*) 1     ),
    (   "-",    liftIntOp (-) 0     )
  ]

