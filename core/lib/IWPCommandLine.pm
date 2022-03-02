=pod
 
=head1 DESCRIPTION
 
This module manages command line arguments.
(c) Corvideon Limited 2016
Seamus Brady <seamus@corvideon.ie>
 
=cut

package IWPCommandline;

use v5.22;
use strict;
use warnings;
use autodie;
use Moo;
use Getopt::Long qw(GetOptions);
use feature qw(signatures say);
no warnings qw(experimental::signatures);

has 'args' => (
    is       => 'rw',
);
 
sub initialise_opts( $self ){
    my $iwproot = "";       # IWP root directory
    my $start = 0;          # Start up IWP and various services
    my $quit = 0;           # Quit IWP and shut down services
    my $docs = 0;           # Open the documentation
    my $about = 0;          # Open the about page
    my $plugins = 0;        # Open the plugins folder
    my $themes  = 0;        # Open the themes folder
    my $mysql = 0;          # Open PHPMyAdmin
    my $wpfrontpage = 0;    # Open the WP front page
    my $wpadmin = 0;        # Open the WP Dashboard
    my $ssh = 0;            # Open an SSH session
    my $monitor = 0;        # Open the QEMU monitor
    my $status = 0;         # Check if IWP is running
    my $webconsole = 0;     # Show webconsole
    my %iwp_args = (
        "iwproot" => $iwproot,
        "start" => $start,
        "quit" => $quit, 
        "docs" => $docs,
        "about" => $about,   
        "plugins" => $plugins,    
        "themes" => $themes,     
        "mysql" => $mysql,
        "wpfrontpage" => $wpfrontpage, 
        "wpadmin" => $wpadmin,     
        "ssh" => $ssh,      
        "monitor" => $monitor,
        "status" => $status,
        "webconsole" => $webconsole
    );
    GetOptions(\%iwp_args,
                'iwproot=s',
                'start',
                'quit', 
                'docs',
                'about',
                'plugins',  
                'themes',     
                'mysql',
                'wpfrontpage',
                'wpadmin',     
                'ssh',     
                'monitor',
                'status',
                'webconsole'
               );
    $self->args(\%iwp_args);
}


1;