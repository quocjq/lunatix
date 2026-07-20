{ inputs, den, ... }:
{
  imports = [
    (inputs.den.namespace "lix" true)
    (inputs.den.namespace "lig" false)
  ];
}
