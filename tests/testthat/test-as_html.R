context("as_html")

test_that("special characters are escaped", {
  out <- rd2html("a & b")
  expect_equal(out, "a &amp; b")
})

test_that("comments converted to html", {
  expect_equal(rd2html("a\n%b\nc"), c("a", "<!-- %b -->", "c"))
})

test_that("simple wrappers work as expected", {
  expect_equal(rd2html("\\strong{x}"), "<strong>x</strong>")
  expect_equal(rd2html("\\strong{\\emph{x}}"), "<strong><em>x</em></strong>")
})

test_that("simple replacements work as expected", {
  expect_equal(rd2html("\\ldots"), "&#8230;")
})

test_that("subsection generates h3", {
  expect_equal(rd2html("\\subsection{A}{B}"), c("<h3>A</h3>", "B"))
})

test_that("if generates html", {
  expect_equal(rd2html("\\if{html}{\\bold{a}}"), "<b>a</b>")
  expect_equal(rd2html("\\if{latex}{\\bold{a}}"), character())
})

test_that("ifelse generates html", {
  expect_equal(rd2html("\\ifelse{html}{\\bold{a}}{x}"), "<b>a</b>")
  expect_equal(rd2html("\\ifelse{latex}{x}{\\bold{a}}"), "<b>a</b>")
})

test_that("code inside Sexpr is evaluated", {
  expect_equal(rd2html("\\Sexpr{1 + 2}"), "3")
})


# links -------------------------------------------------------------------

test_that("href orders arguments correctly", {
   expect_equal(
     rd2html("\\href{http://a.com}{a}"),
     "<a href = 'http://a.com'>a</a>"
   )
})

test_that("can convert cross links to online documentation url", {
  expect_equal(
    rd2html("\\link[base]{library}", current = new_current("library", "pkg.name")),
    link_remote(label = "library", topic = "library", package = "base")
  )
})

test_that("can convert cross links to the same package (#242)", {
  pkgdownindex = list(
    name = "build_site",
    alias = list(build_site.Rd = "build_site")
  )
  current <- new_current("library", "pkg.name")
  expect_equal(
    rd2html("\\link[pkg.name]{library}", index = pkgdownindex, current = current),
    link_local(label = "library", topic = "library", index = pkgdownindex, current = current)
  )
})

test_that("can parse local links with topic!=label", {
  index <- list(name = "a", alias = list("x"), file_out = list("y.html"))
  expect_equal(
    rd2html("\\link[=x]{z}", index = index),
    "<a href='y.html'>z</a>"
  )
})

test_that("functions in other packages generates link to rdocumentation.org", {
  expect_equal(
    rd2html("\\link[stats:acf]{xyz}", current = structure("x", pkg_name = "y")),
    "<a href='http://www.rdocumentation.org/packages/stats/topics/acf'>xyz</a>"
  )

  # Unless it's the current package
  expect_equal(
    rd2html("\\link[y:acf]{xyz}", current = structure("x", pkg_name = "y")),
    "xyz"
  )
})

test_that("link to non-existing functions return label", {
  expect_equal(
    rd2html("\\link[xyzxyz:xyzxyz]{abc}", current = structure("x", pkg_name = "y")),
    "abc"
  )
  expect_equal(
    rd2html("\\link[base:xyzxyz]{abc}", current = structure("x", pkg_name = "y")),
    "abc"
  )
})

test_that("code blocks autolinked to vignettes", {
  expect_equal(
    rd2html("\\code{vignette('abc')}"),
    "<code><a href='../articles/abc.html'>vignette('abc')</a></code>"
  )
})

# Paragraphs --------------------------------------------------------------

test_that("empty lines break paragraphs", {
  expect_equal(
    flatten_para(rd_text("a\nb\n\nc")),
    "<p>a\nb</p>\n<p>c</p>"
  )
})

test_that("block tags break paragraphs", {
  out <- flatten_para(rd_text("a\n\\itemize{\\item b}\nc"))
  expect_equal(out, "<p>a</p><ul>\n<li><p>b</p></li>\n</ul><p>c</p>")
})

test_that("single item can have multiple paragraphs", {
  out <- flatten_para(rd_text("\\itemize{\\item a\n\nb}"))
  expect_equal(out, "<ul>\n<li><p>a</p>\n<p>b</p></li>\n</ul>\n")
})

test_that("nl after tag doesn't trigger paragraphs", {
  out <- flatten_para(rd_text("One \\code{}\nTwo"))
  expect_equal(out, "<p>One <code></code>\nTwo</p>")
})

# Usage -------------------------------------------------------------------

test_that("S4 methods gets comment", {
  out <- rd2html("\\S4method{fun}{class}(x, y)")
  expect_equal(out[1], "# S4 method for class")
  expect_equal(out[2], "fun(x, y)")
})

test_that("S3 methods gets comment", {
  out <- rd2html("\\S3method{fun}{class}(x, y)")
  expect_equal(out[1], "# S3 method for class")
  expect_equal(out[2], "fun(x, y)")
})


test_that("eqn", {
  out <- rd2html(" \\eqn{\\alpha}{alpha}")
  expect_equal(out, "\\(\\alpha\\)")
  out <- rd2html(" \\eqn{\\alpha}{alpha}", mathjax = FALSE)
  expect_equal(out, "<code class = 'eq'>alpha</code>")
  out <- rd2html(" \\eqn{x}")
  expect_equal(out, "\\(x\\)")
  out <- rd2html(" \\eqn{x}", mathjax = FALSE)
  expect_equal(out, "<code class = 'eq'>x</code>")
})

test_that("deqn", {
  out <- rd2html(" \\deqn{\\alpha}{alpha}")
  expect_equal(out, "$$\\alpha$$")
  out <- rd2html(" \\deqn{\\alpha}{alpha}", mathjax = FALSE)
  expect_equal(out, "<pre class = 'eq'>alpha</pre>")
  out <- rd2html(" \\deqn{x}")
  expect_equal(out, "$$x$$")
  out <- rd2html(" \\deqn{x}", mathjax = FALSE)
  expect_equal(out, "<pre class = 'eq'>x</pre>")
})


# Value blocks ------------------------------------------------------------

test_that("leading text parsed as paragraph", {
  expected <- "<p>text</p>\n<dt>x</dt><dd><p>y</p></dd>"

  value1 <- rd_text("\\value{\ntext\n\\item{x}{y}}", fragment = FALSE)
  expect_equal(as_data(value1[[1]])$contents, expected)

  value2 <- rd_text("\\value{text\\item{x}{y}}", fragment = FALSE)
  expect_equal(as_data(value2[[1]])$contents, expected)
})

test_that("leading text is optional", {
  value <- rd_text("\\value{\\item{x}{y}}", fragment = FALSE)
  expect_equal(as_data(value[[1]])$contents, "<dt>x</dt><dd><p>y</p></dd>")
})

test_that("items are optional", {
  value <- rd_text("\\value{text}", fragment = FALSE)
  expect_equal(as_data(value[[1]])$contents, "<p>text</p>")
})


# figures -----------------------------------------------------------------

test_that("figures are converted to img", {
  expect_equal(rd2html("\\figure{a}"), "<img src='figures/a' alt='' />")
  expect_equal(rd2html("\\figure{a}{b}"), "<img src='figures/a' alt='b' />")
  expect_equal(
    rd2html("\\figure{a}{options: height=1}"),
    "<img src='figures/a' height=1 />"
  )
})


# titles ------------------------------------------------------------------

test_that("multiline titles are collapsed", {
  rd <- rd_text("\\title{
    x
  }", fragment = FALSE)

  expect_equal(extract_title(rd), "x")
})

test_that("titles can contain other markup", {
  rd <- rd_text("\\title{\\strong{x}}", fragment = FALSE)
  expect_equal(extract_title(rd), "<strong>x</strong>")
})
