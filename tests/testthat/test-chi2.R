context("test-chi2")

test_that("chi2 method works with speedglm and glm", {
  x <- matrix(runif(140), nrow = 70, ncol = 2)
  cuts <- seq(0, 1, length.out = 4)
  xd <- apply(x, 2, function(col) as.numeric(cut(col, cuts)))
  theta <- t(matrix(c(0, 0, 0, 2, 2, 2, -2, -2, -2), ncol = 3, nrow = 3))
  log_odd <- rowSums(t(sapply(seq_along(xd[, 1]), function(row_id) {
    sapply(
      seq_along(xd[row_id, ]),
      function(element) theta[xd[row_id, element], element]
    )
  })))
  y <- stats::rbinom(70, 1, 1 / (1 + exp(-log_odd)))
  for (test in c(TRUE, FALSE)) {
    for (validation in c(TRUE, FALSE)) {
      for (criterion in c("gini", "aic")) {
        chi2_modele <- chi2_iter(x, y, test = test, validation = validation, criterion = criterion)
        expect_s4_class(chi2_modele, "discretization")
        expect_equal(chi2_modele@method.name, "chi2")
        expect_equal(
          chi2_modele@parameters[-length(chi2_modele@parameters)],
          list(
            x,
            test,
            validation,
            criterion,
            list(list(alp = 0.001, del = 0.5))
          )
        )
        if (is_speedglm_installed() & is_speedglm_predict_installed()) {
          expect_s3_class(chi2_modele@best.disc[[1]], "speedglm")
        }

        with_mock(
          "scoringTools:::is_speedglm_installed" = function() FALSE,
          {
            expect_warning(chi2_modele <- chi2_iter(x, y, test = test, validation = validation, criterion = criterion))
            expect_s4_class(chi2_modele, "discretization")
            expect_equal(chi2_modele@method.name, "chi2")
            expect_equal(
              chi2_modele@parameters[-length(chi2_modele@parameters)],
              list(
                x,
                test,
                validation,
                criterion,
                list(list(alp = 0.001, del = 0.5))
              )
            )
            expect_s3_class(chi2_modele@best.disc[[1]], "glm")
          }
        )
      }
    }
  }
})

test_that("chi2 method throws errors", {
  x <- matrix(runif(50), nrow = 25, ncol = 2)
  cuts <- seq(0, 1, length.out = 4)
  xd <- apply(x, 2, function(col) as.numeric(cut(col, cuts)))
  theta <- t(matrix(c(0, 0, 0, 2, 2, 2, -2, -2, -2), ncol = 3, nrow = 3))
  log_odd <- rowSums(t(sapply(seq_along(xd[, 1]), function(row_id) {
    sapply(
      seq_along(xd[row_id, ]),
      function(element) theta[xd[row_id, element], element]
    )
  })))
  y <- stats::rbinom(25, 1, 1 / (1 + exp(-log_odd)))
  expect_error(chi2_iter(x, y, criterion = "toto"))
  expect_error(chi2_iter(x, y[1:12], criterion = "gini"))
})
