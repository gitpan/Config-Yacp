use Test::More tests =>5;

BEGIN{ use_ok( 'Config::Yacp','use Config::Yacp;'); }

my $config_file="t/config.ini";

my $CY=Config::Yacp->new($config_file);

ok(defined $CY, 'An object was created');

ok($CY->isa('Config::Yacp'),'It is the correct type');

is($$CY{INI},"t/config.ini",'Correct config file loaded');

is($$CY{CM},"#",'Correct default comment marker');

