extends RefCounted
## Shared normalized world <-> viewport transform; contains no campaign state.
var center:=Vector2(.5,.5)
var zoom:=1.0
const MAX_ZOOM:=4.5
var max_zoom:=MAX_ZOOM
var detail_scale:=1.0
func configure_world(physical_scale: float) -> void:
	detail_scale=maxf(1.0,physical_scale/2.0);max_zoom=MAX_ZOOM*detail_scale
func fit_rect(view_size: Vector2) -> Rect2:
	var extent:=Vector2(16,9)*minf(view_size.x/16.0,view_size.y/9.0)
	return Rect2((view_size-extent)*.5,extent)
func clamp_view(view_size: Vector2) -> void:
	zoom=clampf(zoom,1.0,max_zoom)
	var extent:=fit_rect(view_size).size*zoom
	if extent.x<=0 or extent.y<=0: return
	for axis in range(2):
		var half:=minf(.5,view_size[axis]/(extent[axis]*2))
		center[axis]=clampf(center[axis],half,1-half)
func rect(view_size: Vector2) -> Rect2:
	var extent:=fit_rect(view_size).size*zoom
	return Rect2(view_size*.5-center*extent,extent)
func world_at(pixel: Vector2,view_size: Vector2) -> Vector2:
	var paper:=rect(view_size)
	return (pixel-paper.position)/paper.size if paper.size.x>0 else Vector2.ZERO
func pixel_at(world: Vector2,view_size: Vector2) -> Vector2:
	var paper:=rect(view_size)
	return paper.position+world*paper.size
func zoom_at(pixel: Vector2,factor: float,view_size: Vector2) -> void:
	var anchor:=world_at(pixel,view_size)
	zoom=clampf(zoom*factor,1.0,max_zoom)
	var extent:=fit_rect(view_size).size*zoom
	center=anchor-(pixel-view_size*.5)/extent
	clamp_view(view_size)
func pan_pixels(relative: Vector2,view_size: Vector2) -> void:
	var extent:=fit_rect(view_size).size*zoom
	if extent.x<=0 or extent.y<=0: return
	center-=relative/extent;clamp_view(view_size)
func focus(position: Vector2,view_size: Vector2,local_zoom: float=-1) -> void:
	center=position;zoom=2.6*detail_scale if local_zoom<0 else local_zoom;clamp_view(view_size)
func overview(view_size: Vector2) -> void:
	center=Vector2(.5,.5);zoom=1.0;clamp_view(view_size)
func visible_world(view_size: Vector2) -> Rect2:
	return Rect2(world_at(Vector2.ZERO,view_size),view_size/rect(view_size).size).intersection(Rect2(0,0,1,1))
