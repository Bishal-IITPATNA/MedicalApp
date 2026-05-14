"""Add delivery charges to medicine orders and bills

Revision ID: delivery_charges_001
Revises: 
Create Date: 2024-12-19 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'delivery_charges_001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Add columns to medicine_order table
    op.add_column('medicine_order', 
        sa.Column('subtotal_amount', sa.Float(), nullable=True, server_default='0.0')
    )
    op.add_column('medicine_order',
        sa.Column('gst_amount', sa.Float(), nullable=True, server_default='0.0')
    )
    op.add_column('medicine_order',
        sa.Column('delivery_charges', sa.Float(), nullable=True, server_default='0.0')
    )
    
    # Rename existing total_amount temporarily and recreate with proper logic
    # This migration assumes existing total_amount should be treated as subtotal
    op.alter_column('medicine_order', 'total_amount',
                   existing_type=sa.Float(),
                   nullable=False,
                   server_default='0.0')
    
    # Add columns to medicine_bill table
    op.add_column('medicine_bill',
        sa.Column('delivery_charges', sa.Float(), nullable=True, server_default='0.0')
    )


def downgrade():
    # Remove columns from medicine_bill table
    op.drop_column('medicine_bill', 'delivery_charges')
    
    # Remove columns from medicine_order table
    op.drop_column('medicine_order', 'delivery_charges')
    op.drop_column('medicine_order', 'gst_amount')
    op.drop_column('medicine_order', 'subtotal_amount')
