
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rdocumentcloud

<!-- badges: start -->
<!-- badges: end -->

The goal of rdocumentcloud is to serve as an R wrapper for the
DocumentCloud API.

A work in progress.

## To-do list

-   [ ] Align function names/functionality with [Python
    wrapper](https://documentcloud.readthedocs.io/en/latest/)
-   [ ] Add function for single document upload
-   [ ] Better documentation of functions
-   [ ] Formalize as R package
-   [ ] Submit to CRAN
-   [ ] Formal documentation

## Installation

You can install the development version of rdocumentcloud like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(rdocumentcloud)
## basic example code
```

What is special about using `README.Rmd` instead of just `README.md`?
You can include R chunks like so:

``` r
summary(cars)
#>      speed           dist       
#>  Min.   : 4.0   Min.   :  2.00  
#>  1st Qu.:12.0   1st Qu.: 26.00  
#>  Median :15.0   Median : 36.00  
#>  Mean   :15.4   Mean   : 42.98  
#>  3rd Qu.:19.0   3rd Qu.: 56.00  
#>  Max.   :25.0   Max.   :120.00
```

You’ll still need to render `README.Rmd` regularly, to keep `README.md`
up-to-date. `devtools::build_readme()` is handy for this. You could also
use GitHub Actions to re-render `README.Rmd` every time you push. An
example workflow can be found here:
<https://github.com/r-lib/actions/tree/v1/examples>.

## Functions

### Main functions

**Usage**

``` r
#Function to do initial authentication with DocumentCloud API using username and password.
dc_auth('username@email.com', 'my_secret_password')

#Function to refresh authentication tokens.
dc_refresh_token(TKTK)

#Function to perform bulk upload of documents to DocumentCloud. Returns a dataframe
# of paths and destination urls. NOTE: must already be authenticated
upload_documents(file_names, 208620, unlist(auth_response$refresh))
```

### Utility functions

**Usage**

``` r
# Utility function to allow vectorization of multiple requests in a main function.
bulk_put_request(TKTK)

# Utility function that accepts a dataframe and column to check for duplicates, and renames if a duplicate name is found.
dupe_check(TKTK)

#Utility function to test for valid filetypes
#https://www.documentcloud.org/help/tips#file-types-supported
check_filetype(TKTK)
```

## Sources

-   [`documentcloud` Python
    wrapper](https://documentcloud.readthedocs.io/en/latest/)
-   [DocumentCloud API](https://www.documentcloud.org/help/api)
    documentation
-   Example package: [Kyle Walker’s
    tidycensus](https://github.com/walkerke/tidycensus)
-   *[R Packages: Organize, Test, Document and Share Your
    Code](https://r-pkgs.org/)* by Hadley Wickham
