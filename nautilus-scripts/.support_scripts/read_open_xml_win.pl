#! c:\perl\bin\perl.exe
############################################################################
#                       read_open_xml
############################################################################
# This script reads a document that is written in the OpenXML format, such
# as Microsoft Office documents and displays the metadata information that
# are contained in it according to the documentation that Microsoft provides
#
# See further information about the structure here:
#       http://msdn.microsoft.com/en-us/library/aa338205.aspx
#
# This script requires both Archive::Zip and LibXML, 
#
# This script was originally written for Linux, but rewritten to work
# for Windows.  It has only been tested on a Win XP sp3 machine with
# ActiveState ActivePerl 5.10.0. To get the script working from a 
# freshly installed ActivePerl, open a command prompt and add a 
# repository to the package manager:
# 	ppm repo add http://cpan.uwinnipeg.ca/PPMPackages/10xx/
#
# open up the the "Perl Package Manager" and install:
#       Archive-ZIP
#       XML-LibXML
#       XML-LibXML-Common
#
# According to the standard OpenXML documents are compressed using ZIP
# and therefore it is required to unzip the documents that contain the
# metadata information before processing them further.  
# The metadata is then stored in a XML documents.  The file
# _rels/.rels defines the relationships that the document contains
# and therefore it should be the first file that is to be read.
# From there you can find any additional files that contain metadata
# information, most files will contain two metadata information files:
#       DOC.ENDING/docProps/app.xml
#       DOC.ENDING/docProps/core.xml    
#
# This script will read the _rels/.rels file, parse it's input, search
# for any XML file that contains property information of the file and 
# then parse that document and print out the metadata information found
# in it.
#
# Usage:
#       read_open_xml.pl DOCUMENT.ENDING
# Example:
#       read_open_xml.pl readme.docx
#
# Author: Kristinn Gudjonsson
# Version : 0.1
# Date : 12/06/09
#
# Copyright 2009 Kristinn Gudjonsson, security ( a t ) kiddaland ( d o t ) net
############################################################################## 

# define libraries
use strict;
use Archive::Zip qw( :ERROR_CODES );
use XML::LibXML;
use XML::LibXML::Common;
use Encode;
use Win32::API; # to get the location of a temp directory

# define the needed variables
my $buffer_size = 256;
my $doc;
my $zip;
my $status;
my $xml;
my $metadata;
my $property;
my $propertylist;
my @properties;
my @relationships;
my $relationship;
my $parent;
my @list;
my $attrib;
my @targets;
my $encoding;
my $tpath;
my $path;
my $len;

# see if the script was called with an argument
if( $#ARGV < 0 )
{
	print "Wrong usage: need to call script with an argument.\n";
	print "$0 - written by : Kristinn Gudjonsson, copyright 2009\n";
	print "Usage:\n\t$0 DOCUMENT.ending\nExample:\n\t$0 README.docx\n";
	exit 1;
}

# read the parameter (the document)
$doc = $ARGV[0];

# create a ZIP object
$zip = Archive::Zip->new();

# read the Word document, that is the ZIP file
$zip->read( $doc ) == AZ_OK or die "Unable to open Office file\n";

# get a temporary directory
$tpath = new Win32::API( "kernel32", "GetTempPath", 'NP', 'N');

$path = ' ' x $buffer_size;
$len = $tpath->Call(length $path, $path);

if ($len == 0) 
{
	print STDERR "Unable to find a temporary directory\n";
	exit 2;
}
elsif ($len > length $path) 
{
	print STDERR "Buffer for temp directory too small; we need $len bytes. Please adjust the variable \$buffer_size in the code\n";
}
else 
{
	$path = substr($path,0,$len);
}

# extract document information
$status = $zip->extractMember( '_rels/.rels', "$path\\rels.xml" );

die "Unable to extract schema from file, is it really a Office 2007 document (openXML)?\n" if $status != AZ_OK;

# read the rels file
$xml = XML::LibXML->new();
# read inn all the XML
$metadata = $xml->parse_file( "$path\\rels.xml" );

# get all the Relationship nodes
$propertylist = $metadata->getDocumentElement();
@properties = $propertylist->childNodes;

# get the encoding of the document
$encoding = $metadata->encoding();

# examine each one
foreach $property (@properties)
{
	# property is a node
	if( $property->nodeType==ELEMENT_NODE )
	{
		# now we are inside the Relationship tag, find the type
		@relationships = $property->attributes();

		# examine each attribute that is defined for the relationshp
		foreach $relationship ( @relationships )
		{
			# we are trying to find nodes which contain property values for the file
			if( $relationship->toString =~ /.*Type.*prop.*/ )
			{
				# now we have a property that consists of a property file
				# examine each attribute that is assigned to the parent node
				$parent = $relationship->getOwnerElement();
				
				@list = $parent->attributes();
				foreach $attrib ( @list ) 
				{
					# need to find the attribute Target, since that defines
					# the location of the XML document that describes the 
					# metadata information from the document
					if ( $attrib->toString =~ /Target/ )
					{
						# push the name of the metadata document into the array targets
						push( @targets, $attrib->value);
					}
				}
			}
		}
	}	
}
# we no longer need the rels.xml file, so we delete it
unlink( "$path\\rels.xml" ); 

# start by print out general information
print "==========================================================================\n";
print "	cmd line: $0 $doc\n";
print "==========================================================================\n";
print "\n\nDocument name: $doc\n";
print "Date: ", "\n";

# examine all the targets
foreach $attrib (@targets)
{
	# check each property file and process it
	if( $attrib eq "docProps/core.xml" )
	{
		process_file( $attrib, "File Metadata" ) or die ( "Unable to read file metadata\n");
	}
	elsif( $attrib eq "docProps/app.xml" )
	{
		process_file( $attrib, "Application Metadata") or die ( "Unable to read application metadata\n" );
	}
	else
	{
		# unkown property file, let's process it anyway
		process_file($attrib, "Custom Metadata") or die ("Unable to read custom metadata, $attrib\n");
	}
}

print "\ncopyright, Kristinn Gudjonsson, 2009\n";
# now we can exit the script gracefully
exit 0;

# ------------------------------------------------------------------------------------------------------------
#	process_file
# ------------------------------------------------------------------------------------------------------------
# This function reads a XML file that contains metadata
# information from a OpenXML file and prints out all the
# tags that are defined within it.
#
# @param xmlfile A string that contains the path within the ZIP archive that contains metadata information
# @param title A title for the file to be printed out before the metadata is printed
# @return Return false if unsuccessful, else true
sub process_file
{
	my @splits;
	my $xmlfile;
	my $title;

	# assign the xmlfile
	$xmlfile = $_[0];
	$title = $_[1];
	
	$status = $zip->extractMember( $xmlfile, "$path\\file.xml" ) ;
	#$status = $zip->extractMember( 'docProps/core.xml', "$path\\core.xml" ) ;
	die "Unable to extract MetaData from file, is it really a Office 2007 document?\n" if $status != AZ_OK;
	
	# we can now read the file
	
	# create a XML parser
	$xml = XML::LibXML->new();
	
	# read inn all the XML
	$metadata = $xml->parse_file( "$path\\file.xml" );
	
	$propertylist = $metadata->getDocumentElement();
	@properties = $propertylist->childNodes;
	
	# print some header information
	print "--------------------------------------------------------------------------\n";
	print "$title\n";
	print "--------------------------------------------------------------------------\n";
	foreach $property (@properties)
	{
		# property is a node
		if( $property->nodeType==ELEMENT_NODE )
		{
			@splits = split( ':', $property->nodeName );

			# print the MetaData information
			if( $#splits eq 1 )
			{
				print "\t", $splits[1], " = ",  encode( $encoding, $property->textContent), "\n";
			}
			else
			{
				print "\t", $splits[0], " = ",  encode( $encoding, $property->textContent), "\n";
			}
		
		}
	}
	
	unlink( "$path\\file.xml" ); 

	return 1;
}

