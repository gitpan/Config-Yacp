# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok  1\n" unless $loaded;}
use Config::Yacp;
$loaded = 1;
print "ok  1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $file="config.ini";

# Create object
my $cfg1=Config::Yacp->new($file);
if(defined $cfg1){
  print"ok  2\n";
}else{
  print"not ok  2\n";
}

# Get the sections
my @sections=$cfg1->get_sections();

if(scalar @sections == 2){
  print"ok  3\n";
}else{
  print"not ok  3\n";
}

# Get the parameters
my @params;

foreach(@sections){
  my @p=$cfg1->get_parameters($_);
  push @params,@p;
}
if(scalar @params == 4){
  print"ok  4\n";
}else{
  print"not ok  4\n";
}

# Get a specific value
my $value=$cfg1->get_value("Section1","Parameter1");
if($value eq "Value1"){
  print"ok  5\n";
}else{
  print"not ok  5\n";
}

# Create a new object & start testing the error
# functions

my $cfg2=Config::Yacp->new($file);

# Set a new value and check for it
$cfg2->set_value("Section1","Parameter1","Value9");
my $v=$cfg2->get_value("Section1","Parameter1");
if($v eq "Value9"){
  print"ok  6\n";
}else{
  print"not ok  6\n";
}

# Pass an incorrect section name
eval{ $cfg2->set_value("Section9","Parameter9","Value9"); };
if($@){
  print"ok  7\n";
}else{
  print"not ok  7\n";
}

# Pass an incorrect parameter name
eval{ $cfg2->set_value("Section1","Parameter9","Value9"); };
if($@){
  print"ok  8\n";
}else{
  print"not ok  8\n";
}

# Delete a section and make sure it doesn't exist
$cfg2->del_section("Section1");
if(!exists $$cfg2{"Section1"}){
  print"ok  9\n";
}else{
  print"not ok 9\n";
}

# Delete a parameter and make sure it doesn't exist
$cfg2->del_parameter("Section2","Parameter3");
if(!exists $$cfg2{"Section2"}{"Parameter3"}){
  print"ok 10\n";
}else{
  print"not ok 10\n";
}

# Delete a non-existent section and catch the error
eval{ $cfg2->del_section("Section4"); };
if($@){
  print"ok 11\n";
}else{
  print"not ok 11\n";
}

# Delete a non-existent parameter and catch the error
eval{ $cfg2->del_parameter("Section2","key9"); };
if($@){
  print"ok 12\n";
}else{
  print"not ok 12\n";
}

# Save the .ini file and catch any errors.
eval { $cfg1->save_ini; };
if($@){
  print"not ok 13: $@\n";
}else{
  print"ok 13\n";
}

