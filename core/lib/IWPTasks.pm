=pod
 
=head1 DESCRIPTION
 
IWPTasks
This module collects the tasks IWP can run.
(c) Corvideon Limited 2016
Seamus Brady <seamus@corvideon.ie>
 
=cut

package IWPTasks;

use v5.22;
use strict;
use warnings;
use autodie;
use Moo;
use Carp qw( croak );
use if $^O eq 'darwin', "Proc::Terminator";
use LWP::Simple qw($ua head);
use Term::Spinner;
use feature qw(signatures say);
no warnings qw(experimental::signatures);

use constant LOCALHOST => "127.0.0.1";
use constant POWEROFF => "system_powerdown";
use constant REBOOT => "system_reset";
use constant QUIT => "quit";
use constant LOADVM => "loadvm ";
use constant SAVEVM => "savevm ";
use constant DELVM => "delvm";
use constant ANSICONEXE => "win/ansicon.exe";

has 'iwp_env' => (
    is => 'rw',
);

has 'iwp_config' => (
    is => 'rw',
);

# subs for starting IWP services

sub start( $self ){
    
    if ( $self->iwp_env->is_iwp_running( $self->iwp_config ) ){
      $self->status_message();
      return;
    }
    
    say "Starting InstantWP...";

    # start the vm using qemu
    say "Loading the IWPServer VM...";
    
    # copy the qemu exe so we can find it
    $self->iwp_env->copy_qemu_exe($self->iwp_config());
    
    # start it up!
    if($self->iwp_env()->is_windows()){
        system( "start /min ".$self->vm_command_string() ); 
    } else {
        system( $self->vm_command_string() );
    }
    
    # sleep
    my $sleep = $self->iwp_config->get_config_setting("qemu", "SleepSeconds");
    sleep $sleep;
    
    # load the default vm snapshot if UseSnapshots enabled
    my $use_snapshots = $self->iwp_config->get_config_setting("qemu", "UseSnapshots");
    if($use_snapshots eq "yes"){
        $self->load_vm_snaphot_command_string();
    }
    
    # wait for the webserver to load and then hide VM window
    $self->wait_on_vm();
    

    # status message
    $self->status_message();
    
    exit 0;
}


sub wait_on_vm( $self ){
    my $wait_on_vm = $self->iwp_config->get_config_setting("startup", "WaitOnVMStart");
    if($wait_on_vm eq "yes"){
        say "Waiting for IWPServer to start...";
        my $wait_seconds = $self->iwp_config->get_config_setting("startup", "WaitOnVMSeconds");
        my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
        my $wp_url = $self->iwp_config->get_config_setting("shortcuts", "WPFrontPage");
        my $url = "http://".LOCALHOST.":".$http_port."/".$wp_url;
        my $web_server_up = 0;
        my $web_timeout = $self->iwp_config->get_config_setting("startup", "WebCheckTimeoutSeconds");
        my $spinner = Term::Spinner->new();
        $ua->timeout($web_timeout);
        for my $i (1 .. $wait_seconds){
            $spinner->advance();
            if (head($url)) { # is the web server up yet?
                $web_server_up = 1;
            }
            if($web_server_up){
                last;
            } else {
                sleep 1;
            } 
        }
        undef $spinner;
        if($web_server_up){
            say "IWPServer has loaded...";   
        } else {
            say "Oh dear, IWPServer failed to load...";
            exit 0;
        } 
    }
}

sub wait_on_vm_quit( $self ){
    # find the QEMU proc and wait on it
    if($self->iwp_env->is_osx()){
        my $wait_on_vm = $self->iwp_config->get_config_setting("shutdown", "WaitOnVMQuit");
        if($wait_on_vm eq "yes"){
            say "Waiting for IWPServer to close...";
            my $wait_seconds = $self->iwp_config->get_config_setting("shutdown", "WaitOnVMQuitSeconds");
            my $vm_running = 0;
            my $spinner = Term::Spinner->new();
            for my $i (1 .. $wait_seconds){
                $spinner->advance();
                $vm_running = $self->iwp_env->is_iwp_running($self->iwp_config());
                if(!$vm_running){
                    last;
                } else {
                    sleep 1;
                } 
            }
            undef $spinner;
        }
    } else {
        # windows code todo
    }
}

sub quit( $self ){
    say "Quitting InstantWP...";
    
    # save the default vm to a snapshot if UseSnapshots enabled
    my $use_snapshots = $self->iwp_config->get_config_setting("qemu", "UseSnapshots");
    if($use_snapshots eq "yes"){
        $self->del_vm_snaphot(); # delete snapshot if configured
        $self->save_vm_snaphot();
    }
    
    # sleep
    sleep 1;
    
    
    # quit the vm
    say "Qutting the InstantWP Server VM...";
    if($use_snapshots eq "yes"){ 
        system( $self->quit_vm_via_qemu_command_string() );
    } else {
        $self->poweroff_vm();
        $self->wait_on_vm_quit();
    }
    
    # cleanup!
    system( $self->cleanup() );
    
    
    say "Done";
    
    exit 0;
}


sub docs( $self ){
    say "Opening InstantWP documentation...";
    my $docs_dir = $self->iwp_env->docs_dir();
    my $docs_index = $self->iwp_config->get_config_setting("shortcuts", "DocIndexFile");
    $self->open_me( $docs_dir.$docs_index );
    exit 0;
}

sub about( $self ){
    say "Opening InstantWP about page...";
    my $about_dir = $self->iwp_env->docs_dir();
    my $about_index = $self->iwp_config->get_config_setting("shortcuts", "AboutIndexFile");
    $self->open_me( $about_dir.$about_index );
    exit 0;
}

sub plugins( $self ){
    say "Opening InstantWP plugins folder...";
    my $plugins_dir = $self->iwp_config->get_config_setting("shortcuts", "PluginsUrl");
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    $self->open_me("http://".LOCALHOST.":".$http_port."/".$plugins_dir);
    exit 0;
}

sub themes( $self ){
    say "Opening InstantWP theme folder...";
    my $themes_url = $self->iwp_config->get_config_setting("shortcuts", "ThemesUrl");
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    $self->open_me("http://".LOCALHOST.":".$http_port."/".$themes_url);
    exit 0;
}


sub webconsole( $self ){
    say "Opening InstantWP webconsole...";
    my $webconsole_url = $self->iwp_config->get_config_setting("shortcuts", "WebConsoleURL");
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    $self->open_me("http://".LOCALHOST.":".$http_port."/".$webconsole_url);
    exit 0;
}

sub mysql( $self ){
    say "Opening InstantWP PHPMyAdmin...";
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    my $PHPMyAdminUrl = $self->iwp_config->get_config_setting("shortcuts", "PHPMyAdminUrl");
    $self->open_me("http://".LOCALHOST.":".$http_port."/".$PHPMyAdminUrl);
    exit 0;
}


sub wpfrontpage( $self ){
    say "Opening InstantWP WP Front Page...";
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    my $WPDashboard = $self->iwp_config->get_config_setting("shortcuts", "WPFrontPage");
    say "http://".LOCALHOST.":".$http_port."/".$WPDashboard;
    $self->open_me("http://".LOCALHOST.":".$http_port."/".$WPDashboard);
    exit 0;
}

sub wpadmin( $self ){
    say "Opening InstantWP WP Dashboard...";
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    my $WPDashboard = $self->iwp_config->get_config_setting("shortcuts", "WPDashboard");
    $self->open_me("http://".LOCALHOST.":".$http_port."/".$WPDashboard);
    exit 0;
}

sub ssh( $self ){
    say "Opening InstantWP SSH...";
    say "Logging into Instant WordPress Server VM...";
    my $ssh_port = $self->iwp_env->get_port_number($self->iwp_config(), "SSH");
    my $ssh_user = $self->iwp_config->get_config_setting("IWPHostServ", "IWPHostServUser");
    my $ssh_pass = $self->iwp_config->get_config_setting("IWPHostServ", "IWPHostServPassword");
    my $ssh_term = $self->iwp_env->bin_dir()."ssh-term";

    if($self->iwp_env->is_osx()){
        exec($ssh_term." ".LOCALHOST." $ssh_user $ssh_pass $ssh_port");
    } else {
        my $sshclient = $self->iwp_config->get_config_setting("components", "SSHClient");
        $ssh_term = $self->iwp_env->platform_dir().$sshclient;
        system( "start $ssh_term -ssh ".LOCALHOST." -P $ssh_port -l $ssh_user -pass $ssh_pass");
    }
    exit 0;
}

sub monitor( $self ){
    say "Opening InstantWP QEMU Monitor...";
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    if($self->iwp_env->is_osx()){
        # osx telnet session
        exec("telnet ".LOCALHOST." $monitor_port");
    } else{
        my $TelnetBinary = $self->iwp_config->get_config_setting("components", "SSHClient");
        $TelnetBinary = $self->iwp_env->platform_dir().$TelnetBinary;
        my $ansicon = $self->iwp_env->platform_dir().ANSICONEXE;
        system("start $ansicon $TelnetBinary -telnet ".LOCALHOST." -P $monitor_port");
    }
    exit 0;
}

sub status( $self ){
    say "Checking if InstantWP is running...";
    # find the QEMU process
    if($self->iwp_env->is_osx()){
        if( $self->iwp_env->is_iwp_running( $self->iwp_config ) ){
            $self->status_message();
        }  else {
            say "InstantWP does not seem to be running...";
        }
    } else {
        # windows code todo
    }
    exit 0;
}

sub status_message( $self ){
    my $ssh_port = $self->iwp_env->get_port_number($self->iwp_config(), "SSH");
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    say "InstantWP is running!";
    say "HTTP port: $http_port";
    say "SSH port: $ssh_port";
    say "QEMU monitor (telnet) port: $monitor_port";
}

sub run_qemu_command( $self, $TelnetBinary, $monitor_port, $monitor_command){
    if($self->iwp_env()->is_windows()){
        system("$TelnetBinary $monitor_port $monitor_command"); 
    } else {
        system("$TelnetBinary $monitor_port '$monitor_command'"); 
    }
}


sub reboot_vm( $self ){
    say "Rebooting IWPServer...";
    my $TelnetBinary = $self->iwp_config->get_config_setting("components", "IWPQEMUTelnetPath");
    $TelnetBinary = $self->iwp_env->platform_dir().$TelnetBinary;
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    my $monitor_command = REBOOT;
    $self->run_qemu_command( $TelnetBinary, $monitor_port, $monitor_command );
}

sub poweroff_vm( $self ){
    # this powers down the VM rather than just quitting QEMU
    say "Powering off IWPServer...";
    my $TelnetBinary = $self->iwp_config->get_config_setting("components", "IWPQEMUTelnetPath");
    $TelnetBinary = $self->iwp_env->platform_dir().$TelnetBinary;
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    my $monitor_command = POWEROFF;
    $self->run_qemu_command( $TelnetBinary, $monitor_port, $monitor_command );
}



sub cleanup( $self ) {
    say "Clean up any processes left behind...";
    my $cleanup_script = $self->iwp_config->get_config_setting("shutdown", "CleanUpScript");
    $cleanup_script = $self->iwp_env->platform_dir().$cleanup_script;
    system( $cleanup_script );
}


# utility function to open a folder/file/url
sub open_me( $self, $item_to_open){
    if($self->iwp_env->is_osx()){
        system("open ".$item_to_open);
    } else {
        system("start ".$item_to_open);
    }
}

sub del_vm_snaphot( $self ){
    # The command will save the default snapshot before saving
    my $TelnetBinary = $self->iwp_config->get_config_setting("components", "IWPQEMUTelnetPath");
    $TelnetBinary = $self->iwp_env->platform_dir().$TelnetBinary;
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    my $snapshot_name = $self->iwp_config->get_config_setting("qemu", "DefaultSnapshot");
    my $delete_snapshot = $self->iwp_config->get_config_setting("qemu", "DeleteSnapShotBeforeSave");
    if($delete_snapshot eq "yes"){
        my $monitor_command =  DELVM." $snapshot_name";
        $self->run_qemu_command( $TelnetBinary, $monitor_port, $monitor_command );
    }
}
    
sub save_vm_snaphot( $self ){
    # The command to save a particular VM snapshot via telnet into the QEMU monitor
    my $TelnetBinary = $self->iwp_config->get_config_setting("components", "IWPQEMUTelnetPath");
    $TelnetBinary = $self->iwp_env->platform_dir().$TelnetBinary;
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    my $snapshot_name = $self->iwp_config->get_config_setting("qemu", "DefaultSnapshot");
    my $monitor_command = SAVEVM." $snapshot_name";
    $self->run_qemu_command( $TelnetBinary, $monitor_port, $monitor_command );
}


# command strings

sub vm_command_string( $self ){
    # The command to start QEMU and the VM
    
    my $QEMUBinary = $self->iwp_config->get_config_setting("qemu", "QEMUBinary");
    
    if($self->iwp_env->is_windows()){
        $QEMUBinary = $self->iwp_env->win_qemu_exe_path($self->iwp_config);
    } else {
        $QEMUBinary = $self->iwp_env->platform_dir().$QEMUBinary;
    }
   
    my $RAM = $self->iwp_config->get_config_setting("qemu", "RAM");
    
    my $VMFile = $self->iwp_config->get_config_setting("qemu", "VMFile");
    $VMFile = $self->iwp_env->vm_dir().$VMFile;
    
    my $ssh_port = $self->iwp_env->get_port_number($self->iwp_config(), "SSH");
    my $http_port = $self->iwp_env->get_port_number($self->iwp_config(), "HTTP");
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    my $spare1_port = $self->iwp_env->get_port_number($self->iwp_config(), "SparePort1");
    my $spare2_port = $self->iwp_env->get_port_number($self->iwp_config(), "SparePort2");
    my $spare3_port = $self->iwp_env->get_port_number($self->iwp_config(), "SparePort3");
    my $spare4_port = $self->iwp_env->get_port_number($self->iwp_config(), "SparePort4");

    # should we show any QEMU gui?
    my $ShowQEMUWindow = $self->iwp_config->get_config_setting("qemu", "ShowQEMUWindow");
    if($ShowQEMUWindow eq "no"){
        $ShowQEMUWindow = " -nographic ";
    } else {
       undef $ShowQEMUWindow;
    }
    
    # should the system wait for the vm to load?
    my $nowait = $self->iwp_config->get_config_setting("qemu", "NoWait");
    my $amp = " ";
    if($nowait eq "yes"){
        $amp = " &"; # append an ampersand
    }
    
    my $returnString =   "$QEMUBinary ".
                        " -m $RAM ".  
                        " -hda $VMFile -boot order=c ".
                        " -nic user".
                        ",id=iwpnetwork".
                        ",hostfwd=tcp::$ssh_port-:22".
                        ",hostfwd=tcp::".$http_port."-:80". 
                        ",hostfwd=tcp::".$spare1_port."-:5001".
                        ",hostfwd=tcp::".$spare2_port."-:5002".
                        ",hostfwd=tcp::".$spare3_port."-:5003".
                        ",hostfwd=tcp::".$spare4_port."-:5004".
                        " -monitor telnet:127.0.0.1:$monitor_port,server,nowait ".
                        " -name IWPServer-$ssh_port";
            
    if(defined $ShowQEMUWindow){
        $returnString =  $returnString." $ShowQEMUWindow".$amp;
    } else {
        $returnString =  $returnString.$amp;
    }
    return $returnString;
}


sub load_vm_snaphot_command_string( $self ){
    # The command to load a particular VM snapshot via telnet into the QEMU monitor
    
    my $TelnetBinary = $self->iwp_config->get_config_setting("components", "IWPQEMUTelnetPath");
    $TelnetBinary = $self->iwp_env->platform_dir().$TelnetBinary;
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    my $snapshot_name = $self->iwp_config->get_config_setting("qemu", "DefaultSnapshot");
    my $monitor_command = LOADVM." $snapshot_name";
    $self->run_qemu_command( $TelnetBinary, $monitor_port, $monitor_command );
}


sub quit_vm_via_qemu_command_string( $self ){
    # The command to quit VM via telnet into the QEMU monitor
    
    my $TelnetBinary = $self->iwp_config->get_config_setting("components", "IWPQEMUTelnetPath");
    $TelnetBinary = $self->iwp_env->platform_dir().$TelnetBinary;
    my $monitor_port = $self->iwp_env->get_port_number($self->iwp_config(), "Monitor");
    my $monitor_command = QUIT;
    return "$TelnetBinary $monitor_port '$monitor_command'";
}



1;
