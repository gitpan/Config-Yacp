# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Config::Yacp;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $file="config.ini";
my $cfg=Config::Yacp->new($file);
if(defined $cfg){
  print"ok 2\n";
}else{
  print"not ok 2\n";
}

my @sections=$cfg->get_sections();
my $l=@sections;
if($l == 2){
  print"ok 3\n";
}else{
  print"not ok 3\n";
}

my @params;

foreach(@sections){
  my @p=$cfg->get_parameters($_);
  push @params,@p;
}
my $al=@params;
if($al == 4){
  print"ok 4\n";
}else{
  print"not ok 4\n";
}

my $value=$cfg->get_value("Section1","Parameter1");
if($value eq "Value1"){
  print"ok 5\n";
}else{
  print"not ok 5\n";
}
 
