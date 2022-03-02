=pod
 
=head1 DESCRIPTION
 
InstantWP

(c) Corvideon Limited 2016
Seamus Brady <seamus@corvideon.ie>
 
=cut

package InstantWP;

use v5.22;
use strict;
use warnings;
use autodie;
use Moo;
use Carp qw( croak );
use FindBin;
use Try::Tiny;
use lib "$FindBin::Bin/../lib";
use IWPConfig;
use IWPCommandLine;
use IWPEnvironment;
use IWPTasks;
use Encode::Byte;
use feature qw(signatures say);
no warnings qw(experimental::signatures);

my $iwp_opts = IWPCommandline->new();
my $iwp_config = IWPConfig->new();
my $iwp_env = IWPEnvironment->new();
my $iwp_tasks = IWPTasks->new();

sub run( $self ){
    say "-- InstantWP --";
    
    $iwp_opts->initialise_opts();                                   # commandline args loader
    $iwp_env->set_and_validate_iwproot( $iwp_opts );                # check iwproot
    $iwp_config->config_file_path( $iwp_env->config_file_path() );  # load config file 
    $iwp_tasks->iwp_env($iwp_env);                                  # task setup
    $iwp_tasks->iwp_config($iwp_config);                            # task setup
    version_header();                                               # show version
    
    if( $iwp_opts->args->{start} ) {
        $iwp_tasks->start();
    };
    
    if( $iwp_opts->args->{quit} ) {
        $iwp_tasks->quit();
    };
    
    if( $iwp_opts->args->{docs} ) {
        $iwp_tasks->docs();
    };
    
    if( $iwp_opts->args->{about} ) {
        $iwp_tasks->about();
    };
    
    if( $iwp_opts->args->{plugins} ) {
        $iwp_tasks->plugins();
    };
    
    if( $iwp_opts->args->{themes} ) {
        $iwp_tasks->themes();
    };
    
    if( $iwp_opts->args->{mysql} ) {
        $iwp_tasks->mysql();
    };
    
    
    if( $iwp_opts->args->{wpfrontpage} ) {
        $iwp_tasks->wpfrontpage();
    };
    
    if( $iwp_opts->args->{wpadmin} ) {
        $iwp_tasks->wpadmin();
    };
    
    if( $iwp_opts->args->{ssh} ) {
        $iwp_tasks->ssh();
    };
    
    if( $iwp_opts->args->{monitor} ) {
        $iwp_tasks->monitor();
    };
    
    if( $iwp_opts->args->{status} ) {
        $iwp_tasks->status();
    };
    
    if( $iwp_opts->args->{webconsole} ) {
        $iwp_tasks->webconsole();
    };
    
    
    exit 0;
}

sub version_header(){
    my $AppVersion = $iwp_config->get_config_setting("general", "AppVersion");
    my $AppPreferredName = $iwp_config->get_config_setting("general", "AppPreferredName");
    my $AppDate = $iwp_config->get_config_setting("general", "AppDate");
    say "This seems to be InstantWP Version $AppVersion - $AppPreferredName - $AppDate";        
}

my $iwp = InstantWP->new();
$iwp->run();

1;
