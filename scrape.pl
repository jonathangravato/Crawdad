use open qw(:locale);
use strict;
use warnings qw(all);
use HTML::TreeBuilder 5 -weak; # Ensure weak references in use
use URI::Split qw/ uri_split uri_join /;
use HTML::TagFilter;

my @links;

open(FH, "<", "index/site-index.txt")
    or die "Failed to open file: $!\n";
while(<FH>) { 
    chomp; 
    push @links, $_;
} 
close FH;

my $dir = "";
while($dir eq ""){
print "What is the name of the site we are working on? ";
$dir = <STDIN>;
chomp $dir; 
}

mkdir($dir);

my $entities = "";
my $indent_char = "\t";

my $filter = HTML::TagFilter->new(
	allow=>{ 
		div 	=> { class => ['none'], id => ['none'] },
		nav 	=> { class => ['none'], id => ['none'] },
		a 		=> { class => ['none'], id => ['none'], href => [] },
		p 		=> { class => ['none'], id => ['none'] },
		span 	=> { class => ['none'], id => ['none'] },
		ul 		=> { class => ['none'], id => ['none'] },
		li 		=> { class => ['none'], id => ['none'] },
		h1 		=> { class => ['none'], id => ['none'] },
		h2 		=> { class => ['none'], id => ['none'] },
		h3 		=> { class => ['none'], id => ['none'] },
		h4 		=> { class => ['none'], id => ['none'] },
		h5 		=> { class => ['none'], id => ['none'] },
		h6 		=> { class => ['none'], id => ['none'] },
		img 	=> { src => [] }
	},
	log_rejects => 1,
	skip_xss_protection => 1,
	strip_comments => 1
	);

foreach my $url (@links){

	my ($filename) = $url =~ m#([^/]+)$#;

	$filename =~ tr/=/_/;
	$filename =~ tr/?/_/;

	my $currentfile = $dir . '/' . $filename . '.html';

	open (FH, '>', $currentfile)
		or die "Failed to open file: $!\n";

	my $tree = HTML::TreeBuilder->new_from_url($url);
    $tree->parse($url);
    $tree = $tree->look_down('_tag', 'body');
    if($tree){
    	$tree->dump; # a method we inherit from HTML::Element
    	print FH $filter->filter($tree->as_HTML($entities, $indent_char, {}));
    } else{
    	warn "No body tag found";
    }

    

	close FH;

}
