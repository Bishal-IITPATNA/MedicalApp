from flask import Blueprint, request, jsonify
from app import db
from app.models.notification import Notification
from flask_jwt_extended import jwt_required, get_jwt_identity

bp = Blueprint('notifications', __name__, url_prefix='/api/notifications')

def paginate_query(query, page=1, per_page=20):
    """Helper function to paginate query results"""
    try:
        page = int(request.args.get('page', page))
        per_page = int(request.args.get('per_page', per_page))
        per_page = min(per_page, 100)  # Max 100 items per page
    except (ValueError, TypeError):
        page = 1
        per_page = 20
    
    paginated = query.paginate(page=page, per_page=per_page, error_out=False)
    
    return {
        'items': paginated.items,
        'total': paginated.total,
        'page': paginated.page,
        'per_page': paginated.per_page,
        'pages': paginated.pages,
        'has_next': paginated.has_next,
        'has_prev': paginated.has_prev
    }

@bp.route('/', methods=['GET'])
@jwt_required()
def get_notifications():
    """Get user notifications with pagination"""
    current_user_id = get_jwt_identity()
    
    query = Notification.query.filter_by(user_id=current_user_id).order_by(
        Notification.created_at.desc()
    )
    
    # Paginate
    result = paginate_query(query, per_page=30)
    
    return jsonify({
        'notifications': [notif.to_dict() for notif in result['items']],
        'total': result['total'],
        'page': result['page'],
        'per_page': result['per_page'],
        'pages': result['pages'],
        'has_next': result['has_next'],
        'has_prev': result['has_prev']
    }), 200

@bp.route('/<int:notification_id>/read', methods=['PUT'])
@jwt_required()
def mark_as_read(notification_id):
    """Mark notification as read"""
    current_user_id = get_jwt_identity()
    
    notification = Notification.query.filter_by(
        id=notification_id,
        user_id=current_user_id
    ).first()
    
    if not notification:
        return jsonify({'error': 'Notification not found'}), 404
    
    notification.is_read = True
    db.session.commit()
    
    return jsonify({
        'message': 'Notification marked as read'
    }), 200

@bp.route('/mark-all-read', methods=['PUT'])
@jwt_required()
def mark_all_as_read():
    """Mark all notifications as read"""
    current_user_id = get_jwt_identity()
    
    Notification.query.filter_by(
        user_id=current_user_id,
        is_read=False
    ).update({'is_read': True})
    
    db.session.commit()
    
    return jsonify({
        'message': 'All notifications marked as read'
    }), 200

def create_notification(user_id, title, message, notification_type, related_id=None, related_type=None, patient_id=None):
    """Helper function to create a notification"""
    notification = Notification(
        user_id=user_id,
        patient_id=patient_id,
        title=title,
        message=message,
        notification_type=notification_type,
        related_id=related_id,
        related_type=related_type
    )
    db.session.add(notification)
    db.session.commit()
    return notification
