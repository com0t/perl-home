use RISC::visio;

## this is the script return that can be safely returned to RISC (dataplane separation)
##  this will be modified during execution if something other than 'complete' needs to be returned
my $riscreturn = 'complete';

visio::createVisioInfo();

print '||&||' . $riscreturn . '||&||';