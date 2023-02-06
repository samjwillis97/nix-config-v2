{ lib, ... }:

{
    recursiveMergeAttrs = builtins.foldl' lib.recursiveUpdate { };
    mergeMap = lib.foldr lib.recursiveUpdate { };
}
