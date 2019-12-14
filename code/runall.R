
command.arguments <- commandArgs(trailingOnly = TRUE);
data.directory    <- normalizePath(command.arguments[1]);
code.directory    <- normalizePath(command.arguments[2]);
output.directory  <- normalizePath(command.arguments[3]);

# add custom library using .libPaths()
print( data.directory   );
print( code.directory   );
print( output.directory );
cat("\n\n##### Sys.time(): ",format(Sys.time(),"%Y-%m-%d %T %Z"),"\n");

start.proc.time <- proc.time();
setwd( output.directory );

cat("\n##################################################\n");
# source supporting R code
code.files <- c(
    "doLDA.R",
    "getTabularData.R",
    "getTextStatistics.R",
    "installRequiredPkgs.R",
    "xml2csv.R"
    );

for ( code.file in code.files ) {
    source(file.path(code.directory,code.file));
    }

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# install required but not-yet-installed R packages
installRequiredPkgs();

require(dplyr);
require(tidyr);
require(text2vec);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
set.seed(1234567);

RData.raw            <- "raw.RData";
RData.textStatistics <- "textStatistics.RData";
RData.LDA            <- "LDA.RData";

# read and convert data to tabular format
DF.raw <- getTabularData(
	raw_data_folder = file.path(data.directory,"arXiv"),
	file_prefix     = "query-arXiv",
	output_file     = RData.raw
	);

print( str(DF.raw) );

# generate statistics
my.text.statistics <- getTextStatistics(
	DF.input             = DF.raw,
	col.id               = "id",
	col.text             = "summary",
	file_text_statistics = RData.textStatistics
	);

print( str(my.text.statistics) );

# perform Latent Dirichlet Allocation
results.LDA <- doLDA(
    input_matrix = my.text.statistics[["document_term_matrix"]],
    file_output  = RData.LDA,
    n_topics     =  10,
    n_top_words  =  30,
    n_iter       = 100
    );

cat("\n##################################################\n");
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

# print system time to log
cat("\n##### Sys.time(): ",format(Sys.time(),"%Y-%m-%d %T %Z"),"\n");

# print elapsed time to log
stop.proc.time <- proc.time();
cat("\n##### start.proc.time() - stop.proc.time():\n");
print( stop.proc.time - start.proc.time );

