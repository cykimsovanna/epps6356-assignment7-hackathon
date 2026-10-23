library(ggplot2)
library(showtext)
library(plotly)

font_add_google("Quattrocento", "quattrocento")
showtext_auto()

ev_font <- "quattrocento"
ev_colors <- c(
  primary = "purple4",
  secondary = "darkorchid3",
  accent = "violet",
  text = "grey15",
  muted = "grey35",
  grid = "grey90"
)


ev_theme <- function(){
  theme_minimal(
    base_family = ev_font,
    base_size = 16
  ) +
    theme(
      # for chart title
      plot.title = element_text(
        face = "bold",
        size = 25,
        hjust = 0.5,
        color = ev_colors[["text"]]
      ),
      # for chart subtitle
      plot.subtitle = element_text(
        size = 15,
        hjust = 0.5,
        color = ev_colors[["muted"]]
      ),
      # for sources
      plot.caption = element_text(
        size = 12,
        hjust = 0,
        color = ev_colors[["muted"]]
      ),
      # for X-Y axes
      axis.title = element_text(
        color = ev_colors[["text"]]
      ),
      axis.text = element_text(
        size = 15,
        color = ev_colors[["muted"]]
      ),
      # for grid lines
      panel.grid.major = element_line(
        color = ev_colors[["grid"]]
      ),
      panel.grid.minor = element_blank(),
      # for legend position
      legend.position = "bottom"
    )
}