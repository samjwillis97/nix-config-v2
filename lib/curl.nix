{ pkgs, ... }:
{
  mkCurlCommand =
    {
      headers ? { },
      method ? "GET",
      dataFile ? null,
      url,
    }:
    let
      headerKeys = builtins.attrNames headers;
      headerString = builtins.foldl' (acc: v: ''${acc} -H "${v}: ${headers.${v}}"'') "" headerKeys;
    in
    ''
      ${pkgs.curl}/bin/curl --retry-connrefused --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 5 --retry-max-time 45${
        if ((builtins.length headerKeys) > 0) then headerString else ""
      } -X ${method}${if (dataFile != null) then " --data-binary \"@${dataFile}\"" else ""} ${url}
    '';
}
