use Test::More tests=>19;
#1
BEGIN{ use_ok( 'Config::Yacp', 'use Config::Yacp;'); }

#2
my $Config_File="config.ini";
my $CY1=Config::Yacp->new($Config_File);
ok( defined $CY1,               'An object was created');

#3
ok( $CY1->isa('Config::Yacp'),  'Its the correct type');

#4
ok( $$CY1{INI} eq "config.ini", 'Correct config file loaded');

#5
ok( $$CY1{CM} eq "#",           'Correct default comment marker');

#6
my @sections=$CY1->get_sections;
ok( scalar @sections == 2,      'Correct number of sections retrieved');

#7
my @params;
foreach(@sections){
  my @p=$CY1->get_parameters($_);
  push @params,@p;
}
ok( scalar @params == 4,        'Correct number of parameters retrieved');

#8
my $V=$CY1->get_value("Section1","Parameter1");
ok( $V eq "Value1",             'Correct parameter value retrieved');

#9
my $CY2=Config::Yacp->new($Config_File);
$CY2->set_value("Section1","Parameter1","Value9");
my $V2=$CY2->get_value("Section1","Parameter1");
ok( $V2 eq "Value9",            'Changing values works');

#10
eval{ $CY2->set_value("Section9","Parameter9","Value9"); };
ok( defined $@,                 'Verify error routines work');

#11
$CY2->del_section("Section1");
ok( !exists $$CY2{"Section1"},   'Able to delete sections');

#12
$CY2->del_parameter("Section2","Parameter3");
ok( !exists $$CY2{"Section2"}{"Parameter3"}, 'Able to delete parameters' );

#13
my $cm = ";";
my $CY3=Config::Yacp->new($Config_File,$cm);
ok( $$CY3{CM} eq ";", 'Initialize comment marker');

#14
my $cm2="@";
eval{ my $CY4=Config::Yacp->new(Config_File,$cm2); };
ok(defined $@, 'Catch invalid comment marker');

#15
my $cmmnt="Test Comment";
my $CY5=Config::Yacp->new($Config_File);
$CY5->add_comment("Section1","Parameter2",$cmmnt);
ok(defined $$CY5{"Section1"}{"Parameter2"}[1], 'Adding comment to parameter');

#16
my $cmmnt2=$CY5->get_comment("Section1","Parameter2");
ok($cmmnt2 eq "Test Comment", 'Retrieve commment from parameter');

#17
my $cmmnt3="Test Comment 2";
$CY1->set_comment("Section1","Parameter1",$cmmnt3); 
my $change=$CY1->get_comment("Section1","Parameter1");
ok($change eq "Test Comment 2", 'Set new comment');

#18
$CY1->del_comment("Section1","Parameter1"); 
ok(!defined $$CY1{"Section1"}{"Parameter1"}[1], 'Able to delete comment');

#19
eval{$CY1->del_comment("Section1","Parameter2"); };
ok(defined $@, 'Catch deletion of non-existent comment');
 


