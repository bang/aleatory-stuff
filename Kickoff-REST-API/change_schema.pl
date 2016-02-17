use common::sense;

my $dir = 'lib/API/Schema/APIDB/Result';
my $tmpl = q{sed -r 's/table\("/table("opengates./' %s >%s};
opendir my $dh,$dir or die $!;
while(my $file = readdir($dh)){
  next if $file =~ /^\./ or $file =~ /\.new$/ or $file =~ /APIDB\.pm/;
  my $cmd = sprintf($tmpl,join('/',$dir , $file) , join('/',$dir, $file) . '.new');
  system $cmd;
  my $origin = join( '/',$dir , $file) . '.new';
  my $destiny = join( '/', $dir, $file );
  system "mv $origin $destiny";
}
closedir $dh;

exit 1;
