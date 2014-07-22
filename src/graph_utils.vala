/*
 * graph_utils.vala
 *
 * Copyright 2013-2014 Cyriac REMY <raum@no-log.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */

using Cairo;
using Gtk;

public class Point {
    public double x;
    public double y;
    Point _middle;

    public Point(double x, double y) {
        this.x = x;
        this.y = y;
    }
}

public class Line {
    public Point start;
    public Point end;
    Point _middle;

    public Point middle { get { return _middle; } }

    public Line(Point s, Point e) {
        start = s;
        end = e;
        calculate_middle();        
    }
    public Line.from_coordinates(double x1, double y1, double x2, double y2) {
        start = new Point(x1, y1);
        end = new Point(x2, y2);
        calculate_middle();        
    }

    void calculate_middle() {
        _middle = new Point(
            Math.fabs(start.x - end.x) / 2 + Math.fmin(start.x, end.x),
            Math.fabs(start.y - end.y) / 2 + Math.fmin(start.y, end.y));
    }
    public uint hash()  {
        string s = "(" + start.x.to_string() + "," + start.y.to_string() + ")-" +
                   "(" + end.x.to_string() + "," + end.y.to_string() + ")";

        return s.hash();
    }

}

public class Rect  {
    public int left;
    public int top;
    public int right;
    public int bottom;

    public int width { get { return (int) Math.fabs(right - left); } }
    public int height { get { return (int) Math.fabs(bottom - top); } }

    public int center_x { get { return (int) (width / 2) + left; } }
    public int center_y { get { return (int) (height / 2) + top; } }

    public bool is_null { get { return top == -1; } }

    public Rect.Null() {
        top = -1;
        left = -1;
        bottom = -1;
        right = -1;
    }

    public Rect.Coordinates(int x1, int y1, int x2, int y2) {
        top = (int) Math.fmin(y1, y2);
        left = (int) Math.fmin(x1, x2);

        bottom = (int) Math.fmax(y1, y2);
        right = (int) Math.fmax(x1, x2);
    }

    public Rect.Dimensions(int w, int h) {
        top = 0;
        left = 0;

        right = w;
        bottom = h;
    }

    public Rect.Region(int x1, int y1, int w, int h) {
        top = y1;
        left = x1;
        bottom = y1 + h;
        right = x1 + w;
    }

    public void reset() {
        top = -1;
        left = -1;
        bottom = -1;
        right = -1;
    }

    public void set(int x1, int y1, int w, int h) {
        top = y1;
        left = x1;
        bottom = y1 + h;
        right = x1 + w;
    }

    public void put(int x, int y) {
        int h = height;
        int w = width;

        top = y;
        left = x;
        bottom = y + h;
        right = x + w;
    }

    public bool in_rect(int x, int y) {
        return (x >= this.left) && (x <= this.right) &&
               (y >= this.top) && (y <= this.bottom);
    }

    public void display() {
        stdout.printf ("l: %d, t: %d, w: %d, h: %d, cx:%d, cy:%d\n",
                       left, top, width, height, center_x, center_y);
    }

    public void abs() {
        Rect absolute = get_abs();
        left = absolute.left;
        top = absolute.top;
        bottom = absolute.bottom;
        right = absolute.right;
    }

    public Gdk.Rectangle GdkRectangle() {
        Gdk.Rectangle r = Gdk.Rectangle();
        r.x = left;
        r.y = top;
        r.width = width;
        r.height = height;

        return r;
    }

    public Rect get_abs() {
        int x;
        int y;
        int l_width, l_height;

        if (left < right) {
            x = left;
            l_width = right - left;
        }  else {
            x = right;
            l_width = left - right;
        }

        if (top < bottom) {
            y = top;
            l_height = bottom - top;
        } else {
            y = bottom;
            l_height = top - bottom;
        }

        return new Rect.Region(x, y, l_width, l_height);
    }

    public void draw(Context context) {
        Rect r = get_abs();
        context.rectangle (r.left, r.top, r.width, r.height);
        context.stroke();
    }

    public Line top_line() {
        return new Line(new Point(right, top), new Point(left, top));

    }
    public Line bottom_line() {
        return new Line(new Point(right, bottom), new Point(left, bottom));

    }
    public Line left_line() {
        return new Line(new Point(left, top), new Point(left, bottom));

    }
    public Line right_line() {
        return new Line(new Point(right, top), new Point(right, bottom));

    }
}

public class SelectorBuffer  {
    Gdk.Pixbuf top_line = null;
    Gdk.Pixbuf bottom_line = null;
    Gdk.Pixbuf left_line = null;
    Gdk.Pixbuf right_line = null;
    public Rect r = new Rect.Null();
    public bool buffered = false;

    public void reset() {
        buffered = false;
    }

    public void copy(Gdk.Window window, Rect s) {
        buffered = true;
        r = s;

        top_line = Gdk.pixbuf_get_from_window (window, r.left - 1, r.top - 1, r.width + 2, 2);
        bottom_line = Gdk.pixbuf_get_from_window (window, r.left - 1, r.bottom - 1, r.width + 2, 2);
        left_line = Gdk.pixbuf_get_from_window (window, r.left - 1, r.top - 1, 2, r.height + 2);
        right_line = Gdk.pixbuf_get_from_window (window, r.right - 1, r.top - 1, 2, r.height + 2);
    }

    public void paste(Context ctx) {
        if (! buffered) return;

        Gdk.cairo_set_source_pixbuf (ctx, top_line, r.left - 1, r.top - 1);
        ctx.paint();
        Gdk.cairo_set_source_pixbuf (ctx, bottom_line, r.left - 1, r.bottom - 1);
        ctx.paint();
        Gdk.cairo_set_source_pixbuf (ctx, left_line, r.left- 1, r.top - 1);
        ctx.paint();
        Gdk.cairo_set_source_pixbuf (ctx, right_line, r.right - 1, r.top - 1);
        ctx.paint();
    }

    public void invert_rect(Context ctx) {
        buffered = true;

        ctx.save();
        ctx.set_operator(Cairo.Operator.OVER);
        ctx.rectangle (r.left, r.top, r.width, r.height);
        ctx.fill();
        ctx.restore();

    }

    public void restore_rect(Context ctx) {
        if (! buffered) return;

        ctx.save();
        ctx.set_operator(Cairo.Operator.XOR);
        ctx.rectangle (r.left, r.top, r.width, r.height);
        ctx.fill();
        ctx.restore();

    }
}

public class Selector : Rect {
    public SelectorBuffer last = new SelectorBuffer();

    public Selector.Null() {
        top = 0;
        left = 0;
        bottom = 0;
        right = 0;
    }

    public void clean_selection(Context context) {

        last.restore_rect(context);

    }
    /*
    public void draw_selection(Context context, Gdk.Window window) {
        if (last.buffered) {
            last.paste(context);
            Rect r = get_abs();
            last.copy(window, r);
            context.rectangle (r.left, r.top, r.width, r.height);
            context.stroke();
        } else {
            Rect r = get_abs();
            last.copy(window, r);
            context.rectangle (r.left, r.top, r.width, r.height);
            context.stroke();
        }
    }
    */
    public void draw_selection(Context context, Gdk.Window window) {

        if (last.buffered) {
            last.restore_rect(context);
            last.r = get_abs();
            last.invert_rect(context);
        } else {
            last.r = get_abs();
            last.invert_rect(context);
        }

    }

}

public abstract class ArrowHead {
    protected double arrow_lenght_ = 10;
    protected double arrow_degrees_ = 0.3;

    public
    enum ArrowStyle {
        ARROW_OPEN,
        ARROW_SOLID,
        ARROW_DIAMOND,
        ARROW_CIRCLE,
    }

    public
    void calcVertexes(double start_x, double start_y, double end_x, double end_y, out double x1, out double y1, out double x2, out double y2) {
        double angle = Math.atan2 (end_y - start_y, end_x - start_x) + Math.PI;

        x1 = end_x + arrow_lenght_ * Math.cos(angle - arrow_degrees_);
        y1 = end_y + arrow_lenght_ * Math.sin(angle - arrow_degrees_);
        x2 = end_x + arrow_lenght_ * Math.cos(angle + arrow_degrees_);
        y2 = end_y + arrow_lenght_ * Math.sin(angle + arrow_degrees_);
    }

    public abstract void draw(Context ctx, double start_x, double start_y, double end_x, double end_y);

}


public class ArrowOpen : ArrowHead {
    public override void draw(Context ctx, double start_x, double start_y, double end_x, double end_y)  {
        double x1, y1;
        double x2, y2;

        calcVertexes (start_x, start_y, end_x, end_y, out x1, out y1, out x2, out y2);

        ctx.move_to (end_x, end_y);
        ctx.line_to (x1, y1);
        ctx.stroke();

        ctx.move_to (end_x, end_y);
        ctx.line_to (x2, y2);
        ctx.stroke();
    }

}

public class ArrowSolid :  ArrowHead {
    public override void draw(Context ctx, double start_x, double start_y, double end_x, double end_y)  {
        double x1, y1;
        double x2, y2;

        calcVertexes (start_x, start_y, end_x, end_y, out x1, out y1, out x2, out y2);

        ctx.move_to(start_x, start_y);
        ctx.line_to(end_x, end_y);
        ctx.stroke();


        ctx.move_to (end_x, end_y);
        ctx.line_to (x1, y1);
        ctx.line_to (x2, y2);
        ctx.close_path();

        ctx.stroke_preserve();

        ctx.fill();
    }

}

public class ArrowCircle :  ArrowHead {
    public override void draw(Context ctx, double start_x, double start_y, double end_x, double end_y)  {
        double angle = Math.atan2 (end_y - start_y, end_x - start_x) + Math.PI;

        double xc = end_x + arrow_lenght_ * Math.cos(angle);
        double yc = end_y + arrow_lenght_ * Math.sin(angle);


        ctx.arc (xc, yc, arrow_lenght_, 0.0, 2 * Math.PI);

        ctx.stroke_preserve();

        ctx.fill();
    }

}

public class ArrowDiamond : ArrowHead {
    public override void draw(Context ctx, double start_x, double start_y, double end_x, double end_y)  {
        double angle = Math.atan2 (end_y - start_y, end_x - start_x) + Math.PI;

        double x1 = end_x + arrow_lenght_ * Math.cos(angle - arrow_degrees_);
        double y1 = end_y + arrow_lenght_ * Math.sin(angle - arrow_degrees_);
        double x2 = end_x + arrow_lenght_ * Math.cos(angle + arrow_degrees_);
        double y2 = end_y + arrow_lenght_ * Math.sin(angle + arrow_degrees_);
        double x3 = end_x + arrow_lenght_ * 2 * Math.cos(angle);
        double y3 = end_y + arrow_lenght_ * 2 * Math.sin(angle);

        ctx.move_to (end_x, end_y);
        ctx.line_to (x1, y1);
        ctx.line_to (x3, y3);
        ctx.line_to (x2, y2);
        ctx.close_path();

        ctx.stroke_preserve();

        ctx.fill();
    }
}

public class TypedLine : Line {
    ArrowHead a_start = null;
    ArrowHead a_end = null;
    /*
    int x1; int y1;
    int x2; int y2;
    */

    public TypedLine(Point a, Point b) {
        base (a, b);
    }

    public TypedLine.from_coordinates(double x1, double y1, double x2, double y2) {
        base(new Point(x1, y1), new Point(x2, y2));
    }

    public double distance_from(int x, int y) {
        double tmp1;
        double tmp2;
        double tmp3;

        return distance_from_out(x, y, out tmp1, out tmp2, out tmp3);
    }

    public double distance_from_out( int px, int py, out double t, out double qx, out double qy) {
        double kMinSegmentLenSquared = 0.00000001;  // adjust to suit.  If you use float, you'll probably want something like 0.000001f
        double kEpsilon = 1.0E-14;  // adjust to suit.  If you use floats, you'll probably want something like 1E-7f
        double dx = end.x - start.x;
        double dy = end.y - start.y;
        double dx1 = px - start.x;
        double dy1 = py - start.y;

        double segLenSquared = (dx * dx) + (dy * dy);

        if (segLenSquared >= -kMinSegmentLenSquared && segLenSquared <= kMinSegmentLenSquared)  {
            // segment is a point.
            qx = start.x;
            qy = start.y;
            t = 0.0;
            return ((dx1 * dx1) + (dy1 * dy1));
        } else {
            // Project a line from p to the segment [p1,p2].  By considering the line
            // extending the segment, parameterized as p1 + (t * (p2 - p1)),
            // we find projection of point p onto the line.
            // It falls where t = [(p - p1) . (p2 - p1)] / |p2 - p1|^2
            t = ((dx1 * dx) + (dy1 * dy)) / segLenSquared;
            if (t < kEpsilon) {
                // intersects at or to the "left" of first segment vertex (start.x, start.y).  If t is approximately 0.0, then
                // intersection is at p1.  If t is less than that, then there is no intersection (i.e. p is not within
                // the 'bounds' of the segment)
                if (t > -kEpsilon)  {
                    // intersects at 1st segment vertex
                    t = 0.0;
                }
                // set our 'intersection' point to p1.
                qx = start.x;
                qy = start.y;
                // Note: If you wanted the ACTUAL intersection point of where the projected lines would intersect if
                // we were doing PointLineDistanceSquared, then qx would be (start.x + (t * dx)) and qy would be (start.y + (t * dy)).
            } else if (t > (1.0 - kEpsilon)) {
                // intersects at or to the "right" of second segment vertex (end.x, end.y).  If t is approximately 1.0, then
                // intersection is at p2.  If t is greater than that, then there is no intersection (i.e. p is not within
                // the 'bounds' of the segment)
                if (t < (1.0 + kEpsilon)) {
                    // intersects at 2nd segment vertex
                    t = 1.0;
                }
                // set our 'intersection' point to p2.
                qx = end.x;
                qy = end.y;
                // Note: If you wanted the ACTUAL intersection point of where the projected lines would intersect if
                // we were doing PointLineDistanceSquared, then qx would be (start.x + (t * dx)) and qy would be (start.y + (t * dy)).
            } else {
                // The projection of the point to the point on the segment that is perpendicular succeeded and the point
                // is 'within' the bounds of the segment.  Set the intersection point as that projected point.
                qx = start.x + (t * dx);
                qy = start.y + (t * dy);
            }
            // return the squared distance from p to the intersection point.  Note that we return the squared distance
            // as an optimization because many times you just need to compare relative distances and the squared values
            // works fine for that.  If you want the ACTUAL distance, just take the square root of this value.
            double dpqx = px - qx;
            double dpqy = py - qy;
            return ((dpqx * dpqx) + (dpqy * dpqy));
        }

    }

    public void start_style(ArrowHead.ArrowStyle style) {
        //stdout.printf ("a_start : %d\n", (int) style);
        switch (style) {
        case ArrowHead.ArrowStyle.ARROW_OPEN:
            a_start = new ArrowOpen();
            break;
        case ArrowHead.ArrowStyle.ARROW_SOLID:
            a_start = new ArrowSolid();
            break;
        case ArrowHead.ArrowStyle.ARROW_DIAMOND:
            a_start = new ArrowDiamond();
            break;
        case ArrowHead.ArrowStyle.ARROW_CIRCLE:
            a_start = new ArrowCircle();
            break;
        }
    }

    public void end_style(ArrowHead.ArrowStyle style) {
        //stdout.printf ("a_end : %d\n", (int) style);
        switch (style) {
        case ArrowHead.ArrowStyle.ARROW_OPEN:
            a_end = new ArrowOpen();
            break;
        case ArrowHead.ArrowStyle.ARROW_SOLID:
            a_end = new ArrowSolid();
            break;
        case ArrowHead.ArrowStyle.ARROW_DIAMOND:
            a_end = new ArrowDiamond();
            break;
        case ArrowHead.ArrowStyle.ARROW_CIRCLE:
            a_end = new ArrowCircle();
            break;
        }
    }

    public void draw(Context ctx) {
        ctx.move_to(start.x, start.y);
        ctx.line_to(end.x, end.y);

        if (a_start != null)
            a_start.draw(ctx, start.x, start.y, end.x, end.y);

        if (a_end != null)
            a_end.draw(ctx, end.x, end.y, start.x, start.y);

        ctx.stroke();
    }

}

bool point_equal(Point p1, Point p2) {
    return p1.x == p2.x && p1.y == p2.y;
}

Point point_make(double x, double y) {
    return new Point(x, y);
}

Point point_subtract(Point p1, Point p2) {
    return new Point (p1.x - p2.x, p1.y - p2.y);
}

Point point_add(Point p1, Point p2) {
    return new Point(p1.x + p2.x, p1.y + p2.y);
}

Point point_multiply(Point p1, double factor) {
    return new Point(p1.x * factor, p1.y * factor);
}

double point_dot_product(Point p1, Point p2) {
    return (p1.x * p2.x) + (p1.y * p2.y);
}

double point_cross_product(Point p1, Point p2) {
    return (p1.x * p2.y) - (p1.y * p2.x);
}

Line line_make(Point start, Point end) {
    return new Line(start, end);
}

double line_length(Line l) {
    return Math.sqrt(Math.pow(l.start.x - l.end.x, 2.0f) + Math.pow(l.start.y - l.end.y, 2.0f));
}

bool line_intersection(Line l1, Line l2, out Point? pointOfIntersection = null) {
    Point p = l1.start;
    Point q = l2.start;
    Point r = point_subtract(l1.end, l1.start);
    Point s = point_subtract(l2.end, l2.start);

    double s_r_crossProduct = point_cross_product(r, s);
    double t = point_cross_product(point_subtract(q, p), s) / s_r_crossProduct;
    double u = point_cross_product(point_subtract(q, p), r) / s_r_crossProduct;

    if(t < 0 || t > 1.0 || u < 0 || u > 1.0) {
        if (pointOfIntersection != null)
            pointOfIntersection = new Point(0, 0);

        return false;
    } else {
        if(pointOfIntersection != null)
            pointOfIntersection = point_add(p, point_multiply(r, t));;

        return true;
    }
}

bool line_intersect_rectangle(Line l, Rect rect) {
    Rect r = rect.get_abs();

    return (
               line_intersection(l, r.top_line(), null) ||
               line_intersection(l, r.bottom_line(), null)
           );
}

bool line_in_rectangle(Line l, Rect rect) {
    return (
               (l.start.x >= rect.left) && (l.end.x <= rect.right) &&
               (l.start.y >= rect.top) && (l.end.y <= rect.bottom)
           );
}

Rect rectangle_overlap(Rect r1, Rect r2) {
    if (r1.is_null) return r2;
    if (r2.is_null) return r1;
    /*
    	r1.abs();
    	r2.abs();
    */
    int x1 = (int) Math.fmin(r1.left, r2.left);
    int y1 = (int) Math.fmin(r1.top, r2.top);
    int x2 = (int) Math.fmax(r1.right, r2.right);
    int y2 = (int) Math.fmax(r1.bottom, r2.bottom);

    return new Rect.Coordinates(x1, y1, x2, y2);
}

Point intersect_line_circle(Line l, Rect circle) {
    double cX = circle.center_x;
    double cY = circle.center_y;
    double radius = circle.width / 2;

    double dX = l.end.x - l.start.x;
    double dY = l.end.y - l.start.y;

    if ((dX == 0) && (dY == 0))  {
        // A and B are the same points, no wl.start.y to calculate intersection
        return (Point) null;
    }

    double dl = (dX * dX + dY * dY);
    double t = ((cX - l.start.x) * dX + (cY - l.start.y) * dY) / dl;

    // point on a line nearest to circle center
    double nearestX = l.start.x + t * dX;
    double nearestY = l.start.y + t * dY;

    // double dist = point_dist(nearestX, nearestY, cX, cY);
    double dist = Math.sqrt(Math.pow(nearestX - cX, 2) + Math.pow(nearestY-cY, 2));

    if (dist == radius) {
        // line segment touches circle; one intersection point
        return  new Point(nearestX, nearestY);
    } else if (dist < radius) {
        // two possible intersection points
        double dt = Math.sqrt(radius * radius - dist * dist) / Math.sqrt(dl);

        // intersection point nearest to A
        double t1 = t - dt;
        double iX = l.start.x + t1 * dX;
        double iY = l.start.y + t1 * dY;
        if (! (t1 < 0 || t1 > 1))
            return new Point(iX, iY);

        // intersection point farthest from A
        t1 = t + dt;
        iX = l.start.x + t1 * dX;
        iY = l.start.y + t1 * dY;
        if (! (t1 < 0 || t1 > 1) )
            return  new Point(iX, iY);
    } 

    return (Point) null;

}

void show_vignette(Cairo.Context ctx, Point p, string text) {
        Cairo.TextExtents extents;
        ctx.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
        ctx.set_font_size (10);

        ctx.set_source_rgb (1, 1, 1);
        ctx.text_extents (text, out extents);
        ctx.rectangle(p.x - extents.width / 2 - 2 , p.y - extents.height - 2, extents.width + 4, extents.height + 4);
        ctx.fill();

        ctx.set_source_rgb (0,0,0);
        ctx.move_to(p.x - extents.width / 2, p.y);
        ctx.show_text (text);
}
