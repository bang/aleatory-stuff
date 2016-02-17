use strict;
use warnings;

use API;

my $app = API->apply_default_middlewares(API->psgi_app);
$app;

