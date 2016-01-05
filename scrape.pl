use open qw(:locale);
use strict;
use warnings qw(all);
use HTML::TreeBuilder 5 -weak; # Ensure weak references in use
use URI::Split qw/ uri_split uri_join /;
use HTML::TagFilter;
use Try::Tiny;
use HTML::Scrubber::StripScripts;
use HTML::Entities;

my @links;

open(FH, "<", "index/site-index.txt")
    or die "Failed to open file: $!\n";
while(<FH>) { 
    chomp; 
    push @links, $_;
} 
close FH;

my $arr_length = scalar @links;

warn "Current link count: $arr_length \n";

my $dir 	= "";
my $tag 	= "";
my $class 	= "";
my $id 		= "";
my $choice 	= "";
my $answer 	= "";

while($dir eq "" || $tag eq "" ){
	print "What is the name of the site we are working on? ";
	$dir = <STDIN>;
	chomp $dir;

	print "What is the container we are looking for?";
	$tag = <STDIN>;
	chomp $tag; 
}

do { 
	print " Search for ( C )lasses or ( I )D's?";
	$choice = <STDIN>;
	chomp $choice;
	$choice = lc $choice;
} until ($choice eq "c" || $choice eq "i");

if ($choice eq "c"){
	print "Enter classes separated by spaces:";
	$class = <STDIN>;
	chomp $class;
	if ($class eq ""){
		warn "You must enter classes to search for...";
		exit; 
	}
} else {
	print "Enter id of container:";
	$id = <STDIN>;
	chomp $id;
	if ($id eq ""){
		warn "You must enter id to search for...";
		exit; 
	}
}

mkdir($dir);

my $entities = "";
my $indent_char = "\t";

my $filter = HTML::TagFilter->new(
	allow=>{ 
		a 	=> { class => ['none'], id => ['none'], href => [] },
		p 	=> { class => ['none'], id => ['none'] },
		span => { class => ['none'], id => ['none'] },
		ul 	=> { class => ['none'], id => ['none'] },
		li 	=> { class => ['none'], id => ['none'] },
		h1 	=> { class => ['none'], id => ['none'] },
		h2 	=> { class => ['none'], id => ['none'] },
		h3 	=> { class => ['none'], id => ['none'] },
		h4 	=> { class => ['none'], id => ['none'] },
		h5 	=> { class => ['none'], id => ['none'] },
		h6 	=> { class => ['none'], id => ['none'] },
		img 	=> { src => [] },
		script => { 'any' },
		style => { 'any' }
	},
	log_rejects => 1,
	skip_xss_protection => 1,
	strip_comments => 1
	);

foreach my $link (@links){

	my $tree = try { HTML::TreeBuilder->new_from_url($link) };
	if ($tree) {
		my ($filename) = $link =~ m#([^/]+)$#;

		$filename =~ tr/=/_/;
		$filename =~ tr/?/_/;

		my $currentfile = $dir . '/' . $filename . '.html';

		open (FH, '>', $currentfile)
			or die "Failed to open file: $!\n";

	    if ($id eq "") {
	    	$tree = $tree->look_down(
		    	_tag => $tag,
		    	class => $class
		    );
#testing shtuff
		    if ($tree ~~ undef){
		    	do {
	    			warn "$tag with class(es) of $class do(es) not exist on current page.  Look for another? ( Y )es or ( N )o";
			    	$answer = <STDIN>;
					chomp $answer;
					$answer = lc $answer;
	    		}until($answer eq "y" || $answer eq "n");

	    		if ($answer eq "y"){
	    				$class = "";
	    				print "Enter class(es) of container separated by spaces:";
						$class = <STDIN>;
						chomp $class;
						if ($class eq ""){
							warn "You must enter class(es) to search for...";
							exit; 
						}
						$tree = HTML::TreeBuilder->new_from_url($link);
						$tree = $tree->look_down(
					    	_tag => $tag,
					    	id => $class
					    );
	    			} else {
	    				exit;
	    			}
		    }

	    } elsif ($class eq "") {
	    	$tree = $tree->look_down(
		    	_tag => $tag,
		    	id => $id
		    );
#testing shtuff
	    	if ($tree ~~ undef){
	    		do {
	    			warn "$tag with id of $id does not exist on current page.  Look for another? ( Y )es or ( N )o";
			    	$answer = <STDIN>;
					chomp $answer;
					$answer = lc $answer;
	    		}until($answer eq "y" || $answer eq "n");

	    		if ($answer eq "y"){
	    				$id = "";
	    				print "Enter id of container:";
						$id = <STDIN>;
						chomp $id;
						if ($id eq ""){
							warn "You must enter id to search for...";
							exit; 
						}
						$tree = HTML::TreeBuilder->new_from_url($link);
						$tree = $tree->look_down(
					    	_tag => $tag,
					    	id => $id
					    );
	    			} else {
	    				exit;
	    			}
		    }

	    } else {
	    	warn "No ids or classes specified...";
	    	exit;
	    }

	    $tree->dump; 
	    $tree = $filter->filter($tree->as_HTML($entities, $indent_char, {}));
	    $tree = encode_entities($tree, "\xA0-\x{FFFD}");

	    my $hss = HTML::Scrubber::StripScripts->new(
		      Allow_src      => 1,
		      Allow_href     => 1,
		      Allow_a_mailto => 1,
		      Whole_document => 1,
		      Block_tags     => ['hr'],
		   );

		my $clean_html = $hss->scrub($tree);

	    if($tree){
	    	print "Content-type: text/html", "\n"; print "Pragma: no-cache", "\n\n";
			print FH $clean_html;

	    } else{
	    	if ($id eq "") {
		    	warn "Could not find " . $tag . " tag in this file with class(es) of " . $class . ".";
		    } elsif ($class eq "") {
		    	warn "Could not find " . $tag . " tag in this file with id of " . $id . ".";
		    } else {
		    	warn "There may be an error in returned data due to unspecified classes or ids.";
		    	exit;
		    } 
	    }

	} else {
		my $response = $HTML::TreeBuilder::lwp_response;
		if ($response->is_success) {
	        warn "Content of $link is not HTML, it's " . $response->content_type . "\n";
	    } else {
	        warn "Couldn't get $link: ", $response->status_line, "\n";
	    }
	}

	close FH;

	$arr_length = $arr_length - 1;

	warn "Current link count: $arr_length \n";

	if($arr_length < 1) {exit;}
	else {next;}

}
