# Investigate the price per carat of diamonds across
# the different colors of diamonds using boxplots.

# Go to the discussions to
# share your thoughts and to discover
# what other people found.

# You can save images by using the ggsave() command.
# ggsave() will save the last plot created.
# For example...
#                  qplot(x = price, data = diamonds)
#                  ggsave('priceHistogram.png')

# ggsave currently recognises the extensions eps/ps, tex (pictex),
# pdf, jpeg, tiff, png, bmp, svg and wmf (windows only).

# Copy and paste all of the code that you used for
# your investigation, and submit it when you are ready.

# SUBMIT YOUR CODE BELOW THIS LINE
# ===================================================================

# setup
library(ggplot2)
data(diamonds)

# add a 'price_per_carat' column
diamonds$price_per_carat <- diamonds$price / diamonds$carat

# plot boxplots for each color
qplot(data = diamonds,
      x = color,
      y = price_per_carat,
      geom = 'boxplot',
      color = color,
      xlab = 'Color',
      ylab = "Price per Carat")

# save the boxplot to an image
ggsave('price_per_carat_boxplots.png')
