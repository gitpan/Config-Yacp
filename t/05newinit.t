use Test::More tests => 2;
use Config::Yacp;

my $ini="t/config.ini";
my $cy=Config::Yacp->new($ini,";");

my $marker=$cy->get_marker;
is($marker,";",'Correctly set alternate comment marker');

my $cm="@";
eval{ my $cy2=Config::Yacp->new($ini,$cm); };
ok(defined $@,'Catch invalid comment marker');

