use Test::More tests => 3;
use Config::Yacp;

my $ini="t/config.ini";

my $cy=Config::Yacp->new($ini);
$cy->add_comment("Section1","Parameter1","Comment 1");
my $cmmnt=$cy->get_comment("Section1","Parameter1");
is($cmmnt,"Comment 1",'Adding comments works');

$cy->add_section("Section3");
my @sections=$cy->get_sections;
ok(scalar @sections == 3,'Adding sections works');

$cy->add_parameter("Section3","Parameter5","Value5");
my @params=$cy->get_parameters("Section3");
ok(scalar @params == 1,'Adding parameter/values works');
 
