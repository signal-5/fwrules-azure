#!/usr/bin/perl

print '"Server Name";"Private IP";"Public IP";"fqdn";"Firewall Rules"'."\n";
open(IF, "az resource list | grep -e id.*networkInterfaces |");

while ($line=<IF>) {
  if ($line=~/^\s*"id":\s+(".*)/) {
    $ifs=$1;
    chomp $ifs;
    @tempif=split ",",$ifs;
    @interfaces=(@interfaces, @tempif);
  }
}

foreach $if (@interfaces) {
  undef $privateip;
  undef $tnsg;
  undef $tpublicip;
  undef $tvm;
  open(IFD, "az resource show --ids $if |") if $if;
  while($line=<IFD>) {
    chomp $line;
    if($line=~/^\s*"privateIPAddress":\s+(".*)/) {
      $privateip=$1;
    }
    if($line=~/:\s*(".*\/providers\/Microsoft.Network\/networkSecurityGroups\/.*")/) {
      $tnsg=$1;
    }
    if($line=~/:\s*(".*\/providers\/Microsoft.Network\/publicIPAddresses\/.*")/) {
      $tpublicip=$1;
    }
    if($line=~/:\s*(".*\/providers\/Microsoft.Compute\/virtualMachines\/.*")/) {
      $tvm=$1;
    }
  }

  open(VM, "az resource show --ids $tvm |") if $tvm;
  undef $cn;
  while($line=<VM>) {
    chomp $line;
    if($line=~/^\s*"computerName":\s+(".*")/) {
      $cn=$1;
    }
  }
  open(PIP,"az resource show --ids $tpublicip |") if $tpublicip;
  undef $fqdn;
  undef $publicip;
  while($line=<PIP>) {
    chomp $line;
    if($line=~/^\s*"fqdn":\s+(".*")/) {
      $fqdn=$1;
    }
    if($line=~/^\s*"ipAddress":\s+(".*")/) {
      $publicip=$1;
    }
  }
  open(NSG,"az network nsg show --ids $tnsg -o table --query \"securityRules[?access=='Allow'].[name,direction,protocol,destinationPortRange,sourceAddressPrefix,priority]\" |") if $tnsg;
  $delete=<NSG>;
  $delete=<NSG>;
  while($line=<NSG>) {
    chomp $line;
    print "$cn;$privateip;$publicip;$fqdn;$line\n";
  }
}
