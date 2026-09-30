# TP-01 Coordinate accuracy

The firmware tests the center, four corners and four edge midpoints of the
800x480 panel. A white ring with a red center is drawn on the LCD for the
current target; touch that marker with one finger and hold it still. After a
1 s settling period it samples for 2.5 s and reports valid samples, missing
samples, mean coordinate, mean Euclidean error and maximum error. A target is
marked insufficient when fewer than 64 valid samples are received.

Record the per-target errors. Larger errors at edges/corners usually indicate
panel alignment or calibration issues.
