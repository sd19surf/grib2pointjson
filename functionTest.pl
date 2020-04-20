
#######################################################
####   TESTING FUNCTIONS ##############################

#stripped no lib function for time convert


# test string 
# 23:2148325:lon=35.000000,lat=35.000000,val=18288:vt=2020040315:CDCB:d=2020040315:CDCB:4 hybrid level:anl:

my $testString = "vt=2020040315";
print testingTime($testString);

sub getTime(){

my $value;
my $rawValue;
    foreach(@_){
        $rawValue = $_;
    }
    $value = (split/=/,$rawValue)[1];
    $year = substr $value, 0, 4; 
    $mon = substr $value, 4, 2;
    $day = substr $value, 6, 2;
    $hour = substr $value, 8, 2;
 
$datestring = $year.'-'.$mon.'-'.$day.'T'.$hour.':00';

return "This the hour found in my test string: $datestring \n";
}

#sub getTime(){
#my $value;
#my $rawValue;
#    foreach(@_){
#        $rawValue = $_;
#    }
#    $value = (split /=/,$rawValue)[1]; 
#my $format = '%Y%m%d%H';
#my $new_format = '%Y-%m-%dT%H:00';
#my $dt = Time::Piece->strptime($value,$format);
#my $new_dt = $dt->strftime($new_format);
# return $new_dt;  
#}