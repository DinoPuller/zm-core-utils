#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
# 

use strict;
use lib '.';

use LWP::UserAgent;
use Getopt::Long;
use XmlDoc;
use Soap;
use ZimbraSoapTest;

#standard options
my ($sessionId, $authToken, $user, $pw, $host, $help);  #standard
my ($verbose, $im);

GetOptions("u|user=s" => \$user,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           "v" => \$verbose,
           "sessionId=s" => \$sessionId,
           "im" => \$im,
          );

if (!defined($user)) {
  my $usage = <<END_OF_USAGE;
    
USAGE: $0 -u USER [-v] [-at authToken -sessionId sessionID] [-im]
END_OF_USAGE
  die $usage;
}

my %soapargs;
$soapargs{ 'NOTIFY'} = 1;

if (defined($sessionId)) {
  $soapargs{'SESSIONID'} = $sessionId;
}
my $z = ZimbraSoapTest->new($user, $host, $pw, \%soapargs);
$z->verbose(3);

if (defined($sessionId) && defined($authToken)) {
  $z->setAuthContext($authToken, $sessionId, \%soapargs);
} else {
#  print "AUTH REQUEST:\n--------------------";
  $z->doStdAuth();
}

if (defined($im)) { #login to IM
  my $d = new XmlDoc;
  
  my %args = ( );
  
  $args{'wait'} = '1';
  
  $d->add('IMGatewayListRequest', $Soap::ZIMBRA_IM_NS, \%args);

  print ("\nSigning into IM:\n");
  my $response = $z->invokeMail($d->root());
}


while (1) {
  if (!defined($verbose)) {
    $z->verbose(0);
  }
  
  my $d = new XmlDoc;
  
  my %args = ( );
  $args{'wait'} = '1';
  
  $soapargs{'FULLRESPONSE'} = '1';
  $soapargs{'TIMEOUT'} = 10 * 60;
  
  $d->add('NoOpRequest', $Soap::ZIMBRA_MAIL_NS, \%args);
  
  my $response = $z->invokeMail($d->root());

  my $envelope = $response->find_child('Envelope');
  my $header = $response->find_child('Header');
  my $context = $header->find_child('context');
  my $notify = $context->find_child('notify');
  my $notseq = 0;
  if (defined($notify)) {
    $notseq = $notify->attr('seq');
    $z->context()->find_child("notify")->attrs({'seq' => $notseq});
    print $z->to_string_simple($notify);
  }
  sleep(1);
}

#print "REQUEST:\n-------------\n".$z->to_string_simple($d);

