use Test::More tests=>5;
use Config::Yacp;

my $ini="t/config.ini";
my $cy=Config::Yacp->new($ini);

$cy->del_comment("Section2","Parameter3");
ok(!defined $$cy{"Section2"}{"Parameter3"}[1],'Able to delete comments');

$cy->del_parameter("Section2","Parameter3");
ok(!defined $$cy{"Section2"}{"Parameter3"},'Able to delete parameters');

$cy->del_section("Section2");
ok(!defined $$cy{"Section2"},'Able to delete sections');

eval{ $cy->del_comment("Section1","Parameter1"); };
ok(defined $@,'Catch deletion of non existent comment');

eval{ $cy->del_section("INI"); };
ok(defined $@,'Catch deletion of internal parameter');

