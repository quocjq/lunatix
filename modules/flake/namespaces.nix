{ inputs, den, ... }:
{
  imports = [
    (inputs.den.namespace "lix" false)
    (inputs.den.namespace "lig" false)
  ];
}
