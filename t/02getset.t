use Test::More tests => 9;
use Config::Yacp;

my $config_file="t/config.ini";

my $CY=Config::Yacp->new($config_file);

#1
my @sections=$CY->get_sections;
ok(scalar @sections == 2,'Correct number of sections');

#2
my @params;
foreach(@sections){
  my @p=$CY->get_parameters($_);
  push @params,@p;
}
ok(scalar @params == 4,'Correct number of parameters');

#3
my $value=$CY->get_value("Section1","Parameter1");
is($value,"Value1",'Correct parameter value retrieved');

#4
my $CY2=Config::Yacp->new($config_file);

$CY2->set_value("Section1","Parameter1","Value9");
my $value2=$CY2->get_value("Section1","Parameter1");
is($value2,"Value9",'Changing values works');

#5
my $comment=$CY->get_comment("Section2","Parameter3");
is($comment," Comment A",'Retrieve comments');

#6
my $cmmnt="Comment X";
$CY->set_comment("Section2","Parameter3",$cmmnt);
my $change=$CY->get_comment("Section2","Parameter3");
is($change,"Comment X",'Change comment');

#7
eval{ $CY->set_value("Section9","Parameter9","Value9"); };
ok(defined $@,'Error routines work');

#8
my $ini=$CY->get_ini;
is($ini,"t/config.ini",'Got correct ini file');

#9
my $marker=$CY->get_marker;
is($marker,"#",'Got correct comment marker');

