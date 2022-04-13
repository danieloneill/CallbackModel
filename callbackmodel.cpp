#include "callbackmodel.h"

#include <time.h>
#include <QDebug>

CallbackModel::CallbackModel(QObject *parent):
    QAbstractListModel(parent),
    m_rowCount(0),
    m_cache(true),
    m_cacheSize(0),
    m_requestDelay(20)
{
    m_requestTimer.setSingleShot(true);
    connect( &m_requestTimer, SIGNAL(timeout()), this, SLOT(slotRequestData()) );
}

CallbackModel::~CallbackModel()
{
}


void CallbackModel::setRecord( int idx, QVariant record )
{
    m_records[ idx ] = record;

    QModelIndex tl = index( idx, 0 );
    QModelIndex br = index( idx, 0 );

    m_recordsNeeded.removeOne( idx );

    emit dataChanged( tl, br );
}

void CallbackModel::setRecords( int first, QVariant records )
{
    if( records.isNull() || !records.isValid() )
        return;

    QVariantList rl = records.toList();
    if( rl.isEmpty() )
        return;

    int y;
    for( y=0; y < rl.count(); y++ )
    {
        m_records[ y+first ] = rl[ y ];
        m_recordsNeeded.removeOne( y+first );
    }

    QModelIndex tl = index( first, 0 );
    QModelIndex br = index( first + rl.count() - 1, 0 );

    emit dataChanged( tl, br );
}

void CallbackModel::setRows(int count)
{
    int oldcount = m_rowCount;
    const QModelIndex idx;

    if( count == oldcount )
        return;

    if( count > oldcount )
    {
        beginInsertRows( idx, oldcount, count-1);
        m_rowCount = count;
        endInsertRows();
    }
    else
    {
        beginRemoveRows( idx, count, oldcount);
        m_rowCount = count;
        endRemoveRows();

        // If we have data past the index, remove it.
        for( int x=count; x < oldcount; x++ )
            m_records.remove( x );
    }

    emit rowCountChanged();

    QModelIndex tl = index( oldcount, 0 );
    QModelIndex br = index( count, 0 );

    emit dataChanged( tl, br );
}

void CallbackModel::invalidate()
{
    beginResetModel();
    m_rowCount = 0;
    m_records.clear();
    m_recordsNeeded.clear();
    endResetModel();

    emit rowCountChanged();
}

int CallbackModel::rowCount(const QModelIndex & parent) const
{
    if( parent.isValid() )
        return 0;

    return m_rowCount;
}

void CallbackModel::requestData( int row )
{
    if( row > m_rowCount || row < 0 )
        return;

    m_mutex.lock();
    if( m_recordsNeeded.contains(row) )
    {
        m_mutex.unlock();
        return;
    }

    //qDebug() << "requestData(" << row << ")";

    m_recordsNeeded.append( row );
    m_requestTimer.start(m_requestDelay);
    m_mutex.unlock();
}

QVariant CallbackModel::data(const QModelIndex & index, int role) const
{
    Q_UNUSED(role)

    QVariantMap invalid;
    invalid["valid"] = false;

    if( !m_records.contains( index.row() ) )
    {
        ((CallbackModel *)this)->requestData( index.row() );
        //qWarning() << "CallbackModel::data for: " << index.row();
        return invalid;
    }

    QVariant r = m_records[ index.row() ];
    return r;
/*
    if( index.column() >= r.count() )
    {
        ((CallbackModel *)this)->requestData( index.row() );
        return invalid;
    }

    return r[ index.column() ];
*/
}


QVariant CallbackModel::get(int row) const
{
    QVariantMap invalid;
    invalid["valid"] = false;

    if( !m_records.contains( row ) )
    {
        ((CallbackModel *)this)->requestData( row );
        return invalid;
    }

    QVariant r = m_records[ row ];
    return r;
}

QJSValueList CallbackModel::loadedIndexes() const
{
    QJSValueList rows;
    foreach( int idx, m_records.keys() )
        rows.append( QJSValue((uint)idx) );
    return rows;
}

bool CallbackModel::hasIndex(int row, int column, const QModelIndex & parent) const
{
    //qDebug() << "hasIndex(" << row << ", " << column << ")";

    if( parent.isValid() )
        return false;

    if( row > m_rowCount )
        return false;

    if( row < 0 )
        return false;

    if( column > 1 )
        return false;

    return true;
}

void CallbackModel::slotRequestData()
{
    //qDebug() << "slotRequestData()!";
    if( m_recordsNeeded.length() == 0 )
        return;

    std::sort( m_recordsNeeded.begin(), m_recordsNeeded.end() );
    int lowest=m_recordsNeeded.first(), highest=m_recordsNeeded.last();

    qDebug() << "Requesting records between " << lowest << " and " << highest;
    emit recordsRequested( lowest, highest );
}

/*
bool CallbackModel::canFetchMore(const QModelIndex & parent) const
{
    if( parent )
        return;

    if( m_rowCount > m_cacheSize )
        return true;

    return false;
}

void CallbackModel::fetchMore(const QModelIndex & parent)
{
}
*/

QHash<int, QByteArray> CallbackModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[Qt::UserRole] = "entry";
    return roles;
}
