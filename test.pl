
use Time::Piece;
use Time::Seconds;
use Benchmark;
use threads;
use Thread::Queue qw( );
use Thread::Semaphore;


##################################################################################################
## Purpose to build an ensemble TARP file for any station
## using wgrib2 bypasses the need for LEADS and is faster
## wgrib2 is loaded on JET Distro
## output is going to be JSON since it's faster for web code to read it
## written by :John Delaney 2020 (coronavirus)
#################################################################################################

#################################################################################################
## Read in a config file
## built for 557th ensembles only
#################################################################################################


###TEMP VARIABLES UNTIL CONFIG
###Still needs work to have a decent config file reader.

my $config_file = $ARGV[0];
#
if (open(my $fh, '<:encoding(UTF-8)', $config_file)) {
  while (my $row = <$fh>) {
    eval $row;
  }
} else {
  warn "Could not open file '$config_file' $!";
};
####################################################################################################################

####################################################################################################################
##TEMP Variables listing until I get the config read in running better
my $filepath = "C:\\ColdFusion2016\\cfusion\\wwwroot\\grib\\";
my $station_list = "C:\\Coldfusion2016\\cfusion\\wwwroot\\grib\\station_list_shrt.csv";
#my @fhours = qw("0000" "0006" "0012" "0018" "0024" "0030" "0036" "0042" "0048" "0054" "0060" "0066" "0072" "0078" "0084" "0090" "0096" "0102" "0108" "0114" "0120" "0126" "0132" "0138" "0144" "0150");
#my $filename = "GLOBAL.grib2.2020032000.";
#my $filename = "gfs.t12z.pgrb2.0p25.f";
#my @fhours = qw( "000" "003" "006" "009" "012" "015" "018" "021" "024" "027" "030" "033" "036" "039" "042" "045" "048" );

####Gather filenames with extension

if ($filename != ''){
  foreach(@fhours){
      push @files, $filename.$_;
  }
}else{
opendir(DIR, ".");
@files = grep(/\.grb$/,readdir(DIR));
closedir(DIR);
}

#####################################################################################################################

my @threads;
my $sem = Thread::Semaphore->new(15);

my @station_list;
$tS = Benchmark->new;

open my $handle, '<', $station_list;
chomp(@station_list = <$handle>);
close $handle;

my $i = 0;
foreach(@station_list){

    my @parse = split /,/, $_;
    my $lat = @parse[1];
    my $lon = @parse[2];
    my $icao = @parse[0];
    my $thrd = $i++;
    push @threads, threads->new(\&main, $lon, $lat, $icao, $thrd);
}

 foreach(@threads){
     $_->join();
 }   

     $tF = Benchmark->new;
    $told = timediff($tF, $tS);
     print "total run time was:",timestr($told),"\n";




sub main(){
my $paramLat = @_[0];
my $paramLon = @_[1];
my $paramICAO = @_[2];
my $threadNumber = @_[3];
$sem->up;
print "running thread: $threadNumber for $paramICAO\n";
@parseFileName = split /\./, @files[0];
my $outfile = $paramICAO."_".@parseFileName[0]."_tarp.json";
my $HoA; #Hash of Arrays of data
my @jsonArray;
push @{ $HoA{"ICAO"} }, '"'.$paramICAO.'"';

foreach my $file(@files){
    my $newFile = $filepath.$file;
createHashTable($newFile, $paramLat, $paramLon);
}
 
 #change to file print out
unless(open FILE, '>'.$outfile) {
    # Die with error message 
    # if we can't open it.
    die "\nUnable to create $outfile\n";
}
# change the output to json format
for $family (keys %HoA){
    my $dataString = join (",", @{ $HoA{$family} });
    push(@jsonArray, '"'.$family.'":['.$dataString.']');
}
my $jsonString = join ",",@jsonArray;

print FILE "{$jsonString}";
# close the file.
close FILE;
print "finished thread: $threadNumber for $paramICAO\n";
}


sub createHashTable(){
 my $file = @_[0];
 my $lat = @_[1];
 my $lon = @_[2];
 my $time;

my $output = qx(wgrib2 "$file" -lon $lat $lon -vt -var -s);

foreach my $line (split /\n+/, $output){
    my ($recNumber, $byteSector, $data, $vt, $sVar, $time, $varKey ) = split /:/, $line, 7;
        push @{ $HoA{createKey($varKey)} }, '{"time": "'.getTime($vt).'","value":'.getValue($data).'}';
}

}

sub createKey(){
my $rawKey;
my $newKey;
foreach(@_){
$rawKey = $_;
    my ($shortVar, $elevation, $timeref, $type) = split /:/, $rawKey;
    $newKey = $shortVar."-".$elevation."(".$type.")";
}
return $newKey;
}

sub getTime(){
my $value;
my $rawValue;
    foreach(@_){
        $rawValue = $_;
    }
    $value = (split /=/,$rawValue)[1]; 
my $format = '%Y%m%d%H';
my $new_format = '%Y-%m-%dT%H:00';
my $dt = Time::Piece->strptime($value,$format);
my $new_dt = $dt->strftime($new_format);
 return $new_dt;  
}

sub getValue(){
my $value;
my $rawValue;
    foreach(@_){
        $rawValue = $_;
    }
    my($lon,$lat,$val) = split /,/,$rawValue;
    $value = (split /=/,$val)[1]; 
 return $value;
}
