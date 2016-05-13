import Data.HashMap.Strict as H

-- A simple FORTH interpretter. 
--  Features
--    > An in-REPL help reference
--    > Continuation of incomplete lines
--    > Error reporting
--    > ABORT function 'see :H ABORT'
--    > A small set of protected primitives.

-- Initial types

type ForthState = (Mode, IStack, CStack, Dictionary) 

data Mode = Normal | Quit | Abort | Nested [Layer] | ExitLoop deriving Show
data Layer = WordDefine | If | Else | Begin deriving Show

type IStack = [Integer]
initialIStack = []

type CStack = [[String]]
initialCStack = []

data PrimResult = Success IStack | Fail String


-- Type for the symbol dictionary

type Dictionary = H.HashMap String [Entry]

data Entry =
     Prim (IStack -> PrimResult)
   | Def [String]
   | Num Integer
   | Unknown String

instance Show Entry where
  show (Prim f)    = "Prim"
  show (Def s)     = show s
  show (Num i)     = show i
  show (Unknown s) = "Unknown: " ++ s


-- Dictionary helpers

dlookup :: String -> Dictionary -> Entry
dlookup ":" _ = Unknown ":"
dlookup word dict =
    case H.lookup word dict of
        Nothing -> case reads word of
            [(i,"")] -> Num i
            _        -> Unknown word
        Just x  -> head x

dinsert :: String -> Entry -> Dictionary -> Dictionary
dinsert key val dict =
    case H.lookup key dict of
        Nothing -> H.insert key [val] dict
        Just x  -> H.insert key (val:x) dict

dremove :: String -> Dictionary -> Dictionary
dremove key dict = 
    case H.lookup key dict of
        Nothing     -> dict
        Just []     -> H.delete key dict
        Just (x:[]) -> H.delete key dict
        Just (x:xs) -> H.insert key xs dict

protectedNames = [":", ";", ".", ".S", ":H", ":Q", "if", "else", "then", "begin", "exit", 
     "again", "ABORT", "+", "-", "*", "/", "%", "<", ">", "=", "0=", "and", "or", "xor", 
     "not", "dup", "drop", "swap", "rot", ":revert"]

isNameProtected s = aux s protectedNames
    where aux s [] = False 
          aux s (x:xs) 
            | s == x    = True
            | otherwise = aux s xs 

-- Initial Dictionary

wrap2 f (x:y:xs) = Success $ (f y x):xs
wrap2 f _ = Fail "Value stack underflow"

wrap1 f (x:xs) = Success $ (f x):xs
wrap1 f _ = Fail "Value stack underflow"

wrapin1 fwrap f x = f (fwrap x)

wrapin2 fwrap f x y = f (fwrap x) (fwrap y)

wrapout1 fwrap f x = fwrap $ f x

wrapout2 fwrap f x y = fwrap $ f x y

bool2num b = case b of
    True -> -1
    False -> 0

num2bool n
    | n == 0    = False
    | otherwise = True

wrapBool2 f x y = bool2num $ f (num2bool x) (num2bool y)

wrapBool1 f x = bool2num $ f $ num2bool x

xor True True = False
xor False False = False
xor _ _ = True

defineDict :: [(String, Entry)] -> Dictionary
defineDict = Prelude.foldr 
    (\pair -> (\dict -> dinsert (fst pair) (snd pair) dict)) H.empty

dup all@(x:xs) = Success $ x:all
dup _ = Fail "Value stack is empty"

drop' (x:xs) = Success xs
drop' _ = Fail "Value stack already empty"

swap (x:y:xs) = Success $ y:x:xs
swap _ = Fail "Value stack underflow"

rot (x:y:z:xs) = Success $ z:x:y:xs
rot _ = Fail "Value stack underflow"

dictionary = defineDict [
        ( "+",      (Prim $ wrap2 (+))  ),
        ( "-",      (Prim $ wrap2 (-))  ),
        ( "*",      (Prim $ wrap2 (*))  ),
        ( "/",      (Prim $ wrap2 div)  ),
        ( "%",      (Prim $ wrap2 mod)  ),
        ( "<",      (Prim $ wrap2 $ wrapout2 bool2num (<))   ),
        ( ">",      (Prim $ wrap2 $ wrapout2 bool2num (>))   ),
        ( "=",      (Prim $ wrap2 $ wrapout2 bool2num (==))  ),
        ( "0=",     (Prim $ wrap1 $ wrapout1 bool2num (==0)) ),
        ( "and",    (Prim $ wrap2 $ wrapBool2 (&&))   ),
        ( "or",     (Prim $ wrap2 $ wrapBool2 (||))   ),
        ( "xor",    (Prim $ wrap2 $ wrapBool2 (xor))  ), 
        ( "not",    (Prim $ wrap1 $ wrapBool1 (not))  ),
        ( "dup",    (Prim dup)    ),
        ( "drop",   (Prim drop')  ),
        ( "swap",   (Prim swap)   ),
        ( "rot",    (Prim rot)    )
    ]


-- Evaluation helpers

checkPrim f stack = case f stack of
    Fail s     -> putStrLn $ "! " ++ s
    Success xs -> return ()

evalPrim f stack = case f stack of
    Fail s     -> stack
    Success xs -> xs

safeTail list = case list of
    (x:xs) -> xs
    other  -> []

safeHead list = case list of
    (x:xs) -> x
    other  -> []

showHead list = case list of
    (x:xs) -> putStrLn $ show x
    _      -> putStrLn "! Stack is empty"

showFull list = putStrLn $ listToStr list

listToStr [] = ""
listToStr (x:xs) = let pre = (listToStr xs); nxt = (show x) in
    if pre == "" then nxt else pre ++ " " ++ nxt

abortCall (mode, istack, cstack, dict) = do
    putStrLn "! Call aborted. Previous state restored.\n";
    return (Abort, istack, cstack, dict)

twice f x = f (f x)

-- CStack Manipulations

startNew cstack = []:cstack
endCurrent cstack = tail cstack
pushCurrent str cstack = (str:(safeHead cstack)):(safeTail cstack)

-- Build a definition for a new word

compileDef :: ForthState -> IO ForthState
compileDef state@(mode, istack, cstack, dict) = 
    if isNameProtected name then do
        putStrLn $ "\n! Cannot redefine protected name \"" ++ name ++ "\"";
        nustate <- abortCall (Normal, istack, endCurrent cstack, dict)
        return nustate
    else do
        -- putStrLn $ "Adding " ++ name ++ " to dictionary : " ++ (show def);
        return (Normal, istack, endCurrent cstack, dinsert name (Def def) dict)
    where x = reverse (head cstack); def = tail x; name = head x

doRevert [] state = do
    putStrLn "\n! Revert syntax requires a user defined word to revert.\n";
    return state
doRevert (x:xs) state@(mode, istack, cstack, dict) = 
    eval xs (mode, istack, cstack, dremove x dict)

-- Evaluate if statement

combineStr x y = x ++ " " ++ y

doIfEval :: [String] -> ForthState -> IO ForthState
doIfEval words state@(Nested (If:[]), istack, cstack, dict) = do
    -- putStrLn $ "If body : " ++ (Prelude.foldr combineStr "" ifbody);
    -- putStrLn $ "words   : " ++ (Prelude.foldr combineStr "" words);
    case istack of
        (x:xs) -> case x of
            0  -> eval words (Normal, tail istack, rest, dict)
            _  -> eval ifbody (Normal, tail istack, words:rest, dict) 
        _ -> do
            putStrLn "\n! Value stack underflow"
            nustate <- abortCall state
            return nustate
    where ifbody = reverse (head cstack); rest = endCurrent cstack
doIfEval words state@(Nested (Else:[]), istack, cstack, dict) = do
    -- putStrLn $ "If body   : " ++ (Prelude.foldr combineStr "" ifbody);
    -- putStrLn $ "Else body : " ++ (Prelude.foldr combineStr "" elsebody);
    -- putStrLn $ "words     : " ++ (Prelude.foldr combineStr "" words);
    case istack of
        (x:xs) -> case x of
            0  -> eval elsebody (Normal, tail istack, words:rest, dict)
            _  -> eval ifbody   (Normal, tail istack, words:rest, dict) 
        _ -> do
            putStrLn "\n! Value stack underflow"
            nustate <- abortCall state
            return nustate
    where ifbody = reverse (head (tail cstack)); elsebody = reverse (head cstack); rest = twice endCurrent cstack

-- Evaluate begin-again loop

doBeginEval :: [String] -> ForthState -> IO ForthState
doBeginEval words state@(Nested nest, istack, cstack, dict) =
    aux loopbody (Normal, istack, [], dict) where 
        loopbody = reverse (head cstack)
        rest = (endCurrent cstack)
        aux _ (ExitLoop, i, c, d) = eval words (Normal, i, rest, d)
        aux _ (Abort, i, c, d) = eval words (Abort, i, rest, d)
        aux _ (Quit, i, c, d) = eval words (Quit, i, rest, d)
        aux _ state = do
            -- putStrLn $ "looping";
            nustate <- eval loopbody state
            aux [] nustate

-- Help command
doHelpEval [] state@(_, _, _, dict) = do
    putStrLn "\nThe .H command will provide help for this interpreted version of Forth.";
    putStrLn "Use .H followed by any command to learn about it. This tool can be used to";
    putStrLn "view the source code of a user created function.\n";
    putStrLn "Available functions: \n . .S :Q :H : ; if else then begin again exit ABORT";
    putStrLn $ (Prelude.foldr combineStr "" (keys dict)) ++ "\n";
    return state
doHelpEval (x:xs) state@(mode, istack, cstack, dict) = case word of
    Num  _ -> do 
        putStrLn "\nInteger, any number entered will be pushed to the stack.\n";
        eval xs state
    Prim f -> case x of
        "dup" -> do
            putStrLn "\n Duplicates the top element on the stack.\n";
            eval xs state
        "drop" -> do
            putStrLn "\n Drops the top element from the stack.\n";
            eval xs state
        "swap" -> do
            putStrLn "\n Swaps the order of the first and second element of the stack.\n";
            eval xs state
        "rot" -> do
            putStrLn "\n Moves the third element of the stack to the top. The original";
            putStrLn "first and second elements are demoted.\n";
            eval xs state
        _ -> do
            putStrLn "\nA mathematical operator. Pops necessary elements from the stack";
            putStrLn "and uses them on the operator in First-In-First-Out order. The";
            putStrLn "result is pushed back onto the stack. Ex: '1 2 -' yields '-1'\n";
            putStrLn "Binary operators: + - * / % < > = and or xor";
            putStrLn "Unary operators: 0= not\n";
            putStrLn "Boolean values in Forth are as follows:\n0 is False, anything else is True.\n";
            eval xs state
    Def s -> do 
        putStrLn "\nUser defined word. Expanded to the following:";
        putStrLn $ (Prelude.foldr combineStr "" s) ++ "\n";
        eval xs state
    Unknown "." -> do
        putStrLn "\nRemoves the top number from the stack and displays it.\n";
        eval xs state
    Unknown ".S" -> do
        putStrLn "\nShows the contents of the stack.\n";
        eval xs state
    Unknown ":Q" -> do
        putStrLn "\nQuits the interpreter.\n";
        eval xs state
    Unknown ":H" -> do
        nustate <- doHelpEval [] state;
        eval xs nustate 
    Unknown ":" -> do
        putStrLn "\nBegin defining a user word. First word following the ':' will be";
        putStrLn "the name, remaining words will make up the body of the new word.\n";
        eval xs state
    Unknown ":revert" -> do
        putStrLn "\nRevert definition of a word to a previous definition. Note that";
        putStrLn "reverted definition is unrecoverable. Undefines a word if there";
        putStrLn "was no previous definition.\n";
        eval xs state
    Unknown ";" -> do
        putStrLn "\nFinish defining a word. Will fail if there are detectable errors.\n";
        eval xs state
    Unknown "if" -> do
        putStrLn "\nBegins a conditional evaluation. All words following 'if' and before";
        putStrLn "a matching 'else' or 'then' will be evaluated if the condition is true.";
        putStrLn "otherwise all words between the matching 'else' (optional) and matching";
        putStrLn "'then' will be evaluated. The condition is considered true if the first";
        putStrLn "value on the stack is non-zero. The first stack value is consumed.\n";
        eval xs state
    Unknown "else" -> do
        putStrLn "\nBegins the matching 'else' body for an 'if' statement. See ':H if'\n";
        eval xs state
    Unknown "then" -> do
        putStrLn "\nCloses an 'if' or correspdoning 'else' body, causing it to be"
        putStrLn "evaluated. Will fail if there are detectable errors. See ':H if'\n";
        eval xs state
    Unknown "begin" -> do
        putStrLn "\nBegins a loop. All words until the matching 'again' command will"
        putStrLn "be repeated until an 'exit' command is evaluated.\n";
        eval xs state
    Unknown "again" -> do
        putStrLn "\nCloses a loop started with 'begin'. See ':H begin'\n";
        eval xs state
    Unknown "exit" -> do
        putStrLn "\nExits a 'begin'/'again' loop. See ':H begin'\n";
        eval xs state
    Unknown "ABORT" -> do
        putStrLn "\nAborts the currently executing line of code (Top level, from REPL)."
        putStrLn "This will causes no state changes resulting from the aborted line."
        putStrLn "The word immediately following the ABORT line will be printed.\n";
        eval xs state     
    where word = dlookup x dict;

-- The Evaluator

eval :: [String] -> ForthState -> IO ForthState

-- No words, no call stack, return to input
eval [] state@(_, _, [], _) = return state

-- If mode is WordDefine and the incoming words are emtpy,
-- allow the user to continue the definition on furth inputs.
-- Print a message to explain the state.
eval [] state@(Nested (WordDefine:[]), _, _, _) = do
    putStrLn "Finish entering word definition, use ; to finish."; 
    return state

-- If mode is Nested and the incoming words are empty,
-- show the user which open bodies need to be finished.
eval [] state@(Nested nest, _, _, _) = do
    putStrLn $ "Open bodies: " ++ (show nest);
    return state

-- End of call, pop call stack
eval [] state@(mode, istack, (cx:cxs), dict) = eval cx (mode, istack, cxs, dict)

-- Normal operation
eval (x:xs) state@(Normal, istack, cstack, dict) = case word of
    Num i  -> eval xs (Normal, i:istack, cstack, dict)
    Prim f -> do { 
        case (f istack) of
            Fail s       -> do 
                putStrLn $ "! " ++ s; 
                nustate <- abortCall state
                return nustate
            Success istk -> eval xs (Normal, istk, cstack, dict)
    }
    Def s  -> eval s (Normal, istack, xs:cstack, dict)
    Unknown "."  -> do 
        showHead istack; 
        eval xs (Normal, safeTail istack, cstack, dict)
    Unknown ".S" -> do 
        showFull istack; 
        eval xs state
    Unknown ":Q" -> return (Quit, istack, cstack, dict)
    Unknown ":H" -> doHelpEval xs state
    Unknown "if" -> eval xs (Nested [If], istack, startNew cstack, dict)  -- new callStack for 'if' body
    Unknown ":"  -> eval xs (Nested [WordDefine], istack, startNew cstack, dict)  -- new cstack for word body
    Unknown "begin" -> eval xs (Nested [Begin], istack, startNew cstack, dict)  -- new cstack for loop body
    Unknown "exit"  -> return (ExitLoop, istack, cstack, dict)
    Unknown ":revert" -> doRevert xs state 
    Unknown "ABORT" -> do
        case xs of
            (y:ys) -> putStrLn $ "\n! ABORT Called : "++y
            _ -> putStrLn "\n! ABORT called : No commands follow"
        nustate <- abortCall state
        return nustate
    other -> do 
        putStrLn $ "\n! Unhandled command: " ++ x ++ " [" ++ (show word) ++ "]"; 
        nustate <- abortCall state
        return nustate
    where word = dlookup x dict 



-- 'begin' is always allowed in a nested state
eval ("begin":xs) state@(Nested nest@(n:ns), istack, cstack, dict) =
    eval xs (Nested (Begin:nest), istack, pushCurrent "begin" cstack, dict)

-- 'if' is always allowed in a nested state
eval ("if":xs) state@(Nested nest@(n:ns), istack, cstack, dict) = 
    eval xs (Nested (If:nest), istack, pushCurrent "if" cstack, dict)



-- If Nested statement is lowest level, 'else' should 
-- create a new call stack to store the else body, otherwise
-- just convert top of nest to else and push 'else'
eval ("else":xs) state@(Nested nest@(If:ns), istack, cstack, dict) = case ns of
    [] -> eval xs (Nested (Else:[]), istack, startNew cstack, dict)
    ns -> eval xs (Nested (Else:ns), istack, pushCurrent "else" cstack, dict)

-- If Nested call stack is closed by 'then', evaluate if statement
eval ("then":xs) state@(Nested nest@(n:[]), _, _, _) = case n of
    If   -> doIfEval xs state
    Else -> doIfEval xs state

-- Close if/else bodies
eval ("then":xs) state@(Nested nest@(n:ns), istack, cstack, dict) = case n of
    If   -> eval xs (Nested ns, istack, pushCurrent "then" cstack, dict)
    Else -> eval xs (Nested ns, istack, pushCurrent "then" cstack, dict)

-- Semicolon will end a properly closed word definition
eval (";":xs) state@(Nested nest@(WordDefine:[]), _, _, _) = do
    nustate <- compileDef state
    eval xs nustate

-- 'again' will end a properly close 'begin'
eval ("again":xs) state@(Nested (Begin:ns), istack, cstack, dict) = case ns of
    [] -> doBeginEval xs state
    ns -> eval xs (Nested ns, istack, pushCurrent "again" cstack, dict)



-- Possible errors
eval (":":xs) state@(Nested nest, istack, cstack, dict) = do
    putStrLn "\n! Word definitions must be top level. Current definition discarded."; 
    nustate <- abortCall $ (Normal, istack, endCurrent cstack, dict)
    return nustate

eval ("else":xs) state@(Nested nest@(Else:ns), istack, cstack, dict) = do
    putStrLn $ "\n! Cannot have 2 'else' blocks in the same if statement. Expected 'then'."
    nustate <- abortCall $ (Normal, istack, twice endCurrent cstack, dict) -- remove if bodies
    return nustate

eval ("then":xs) state@(Nested nest@(WordDefine:[]), istack, cstack, dict) = do
    putStrLn "\n! Error in word definition body.";
    putStrLn "Encountered 'then' with no matching 'if'\n";
    nustate <- abortCall $ (Normal, istack, endCurrent cstack, dict)
    return nustate     

eval ("then":xs) state@(Nested nest, istack, cstack, dict) = do
    putStrLn $ "\n! If/else block has unclosed bodies."
    putStrLn $ "! Unclosed bodies: " ++ (Prelude.foldr combineStr "" (head cstack));
    nustate <- abortCall $ (Normal, istack, endCurrent cstack, dict)
    return nustate

eval (";":xs) state@(Nested nest, istack, cstack, dict) = do
    putStrLn $ "\n! Word definition has unclosed bodies. Definition discarded."
    putStrLn $ "! Unclosed bodies: " ++ (Prelude.foldr combineStr "" (head cstack));
    nustate <- abortCall $ (Normal, istack, endCurrent cstack, dict)
    return nustate

eval ("again":xs) state@(Nested nest@(WordDefine:[]), istack, cstack, dict) = do
    putStrLn "\n! Error in word definition body.";
    putStrLn "Encountered 'again' with no matching 'begin'\n";
    nustate <- abortCall $ (Normal, istack, endCurrent cstack, dict)
    return nustate     

eval ("again":xs) state@(Nested nest, istack, cstack, dict) = do
    putStrLn $ "\n! Begin-Again loop has unclosed bodies. "
    putStrLn $ "! Unclosed bodies: " ++ (Prelude.foldr combineStr "" (head cstack));
    nustate <- abortCall $ (Normal, istack, endCurrent cstack, dict)
    return nustate
 
 


-- All input in a nested state, unless otherwise dealt with,
-- is appended to the current call stack
eval (x:xs) state@(Nested nest@(n:ns), istack, cstack, dict) =
    eval xs (Nested nest, istack, pushCurrent x cstack, dict)

eval (x:xs) state@(mode, i, c, d) = do
    putStrLn $ "Unprocessed command: \"" ++ x ++ "\" state: " ++ (show state)
    return state

-- The REPL

repl :: ForthState -> IO ForthState
repl state@(Quit, _, _, _) = return state
repl state = do 
    putStr "> " ;
    input <- getLine
    nustate <- eval (words input) state
    case nustate of
        (ExitLoop, _, _, _) -> do
            putStrLn "! The 'exit' command is not valid outside of a 'begin'/'again' loop."
            nustate2 <- abortCall nustate
            repl nustate2
        (Abort, _, _, _) -> repl state
        otherwise -> repl nustate

main = do
    putStrLn "\nWelcome to your forth interpreter! Type :Q to quit, :H for help\n"
    repl (Normal, initialIStack, initialCStack, dictionary)
    putStrLn "\nExiting interpreter.\n"
