#!/usr/bin/runhaskell

import System.Directory
import System.FilePath
import Control.Monad

main = do
    path <-getCurrentDirectory
    absolute <-canonicalizePath (path ++ "/../../../build/root")

    putStrLn "module filelist;"
    --putStr "const char Files[][] = {\""
    putStrLn "import embeddedfs;\nvoid fileList(){"

    result <-walkM absolute notDir

    putStr $ foldl1 (++) $ map (wrapper) $ map (abbv absolute) result

    putStrLn "}"


--- Helpers ---
wrapper a = "\tEmbeddedFS.makeFile!(\"" ++ a ++ "\")();\n"

abbv [] (y:ys) = ys
abbv (x:xs) (y:ys) = abbv xs ys

notDir f = do 
    dir <- doesDirectoryExist f
    return $ not dir


--- ---

walkM :: FilePath -> (FilePath -> IO Bool) -> IO [FilePath]
walkM d f = do

  -- Set the current directory
  setCurrentDirectory d

  -- Now get current directory
  files <- getDirectoryContents d

  -- Filter out . and ..
  let files' = filter (\x -> x /= "." && x /= "..") files

  -- Now run the user defined filter
  files'' <- filterM f files'

  -- Add the full path to the file names
  let acc = map (d </>) files''

  -- Get just the sub-directories and start traversing them as well
  subd <- filterM (doesDirectoryExist) files'

  -- Put the full path on the directories as well
  let subd' = map (d </>) subd

  -- Perform the actual walk
  foo <- mapM (`walkM` f) subd'

  let acc' = concat foo

  return (acc' ++ acc)
