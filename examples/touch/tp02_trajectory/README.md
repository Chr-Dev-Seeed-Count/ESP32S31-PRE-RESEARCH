# TP-02 Continuous trajectory

The LCD displays a green trail and a colored live marker. For each case, wait
for the prompt, touch the screen, perform one gesture, then release. The
firmware automatically ends a normal gesture after release; long press ends
after a three-second hold.

The test polls GT1151 every 2 ms. `sample_rate` is calculated only over the
active-contact interval, so it is not diluted by idle time. `large_steps`
counts adjacent coordinates that differ by more than 120 pixels; this can be
caused by a genuinely fast finger movement and is not by itself an I2C error.

The `DIAG` line separates `read_err` (I2C/driver failures), `no_point` (normal
polls without an active finger), `short_dropouts` (temporary no-point periods
during a contact), and `interval_gt_30ms` (slow point delivery). `read_avg`
and `read_max` show the software read-call time. LCD refresh is limited to
50 Hz so feedback does not intentionally dominate the 2 ms polling loop.
