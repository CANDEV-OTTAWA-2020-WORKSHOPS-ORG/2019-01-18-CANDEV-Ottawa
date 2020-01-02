
command.arguments <- commandArgs(trailingOnly = TRUE);
data.directory    <- normalizePath(command.arguments[1]);
code.directory    <- normalizePath(command.arguments[2]);
output.directory  <- normalizePath(command.arguments[3]);

# add custom library using .libPaths()
print( data.directory   );
print( code.directory   );
print( output.directory );
print( format(Sys.time(),"%Y-%m-%d %T %Z") );

start.proc.time <- proc.time();

# set working directory to output directory
setwd( output.directory );

##################################################
# source supporting R code
code.files <- c(
    "doLDA.R",
    "getFeatures.R",
    "getTabularData.R",
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

RData.raw      <- "raw.RData";
RData.features <- "features.RData";
RData.LDA      <- "LDA.RData";

# read and convert data to tabular format
DF.raw <- getTabularData(
	raw_data_folder = file.path(data.directory,"arXiv"),
	file_prefix     = "query-arXiv",
	output_file     = RData.raw
	);

print( str(DF.raw) );

# generate features
list.features <- getFeatures(
    input_matrix  = DF.raw,
	col_id        = "id",
	col_text      = "summary",
	file_features = RData.features
	);

print( str(list.features) );

# perform Latent Dirichlet Allocation
results.LDA <- doLDA(
    input_matrix = list.features[["document_term_matrix"]],
    file_output     = RData.LDA,
    DF.raw          = DF.raw,
    n_topics        =  10,
    n_top_words     =  30,
    n_iter          = 100,
    heatmap_palette = circlize::colorRamp2(c(-1,0,0.5,1), c("black","white","yellow","red"))
    );

##################################################
print( warnings() );

print( getOption('repos') );

print( .libPaths() );

print( sessionInfo() );

print( format(Sys.time(),"%Y-%m-%d %T %Z") );

stop.proc.time <- proc.time();
print( stop.proc.time - start.proc.time );

