use Test::More tests=>10;
BEGIN{ use_ok( 'Config::Yacp', 'Config::Yacp loaded'); }

my $Config_File="config.ini";
my $CY1=Config::Yacp->new($Config_File);

ok( defined $CY1,               'An object was created');
ok( $CY1->isa('Config::Yacp'),  'Its the correct type');

my @sections=$CY1->get_sections;
ok( scalar @sections == 2,      'Correct number of sections retrieved');

my @params;
foreach(@sections){
  my @p=$CY1->get_parameters($_);
  push @params,@p;
}
ok( scalar @params == 4,        'Correct number of parameters retrieved');

my $V=$CY1->get_value("Section1","Parameter1");
ok( $V eq "Value1",             'Correct parameter value retrieved');

my $CY2=Config::Yacp->new($Config_File);
$CY2->set_value("Section1","Parameter1","Value9");
my $V2=$CY2->get_value("Section1","Parameter1");
ok( $V2 eq "Value9",            'Changing values works');

eval{ $CY2->set_value("Section9","Parameter9","Value9"); };
ok( defined $@,                 'Verify error routines work');

$CY2->del_section("Section1");
ok( !exists $$CY2{"Section1"},   'Able to delete sections');

$CY2->del_parameter("Section2","Parameter3");
ok( !exists $$CY2{"Section2"}{"Parameter3"}, 'Able to delete parameters' );

 
