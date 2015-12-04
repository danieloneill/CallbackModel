#ifndef CALLBACKMODEL_H
#define CALLBACKMODEL_H

#include <QAbstractListModel>
#include <QHash>
#include <QList>
#include <QMutex>
#include <QQuickItem>
#include <QTimer>
#include <QVariant>

class CallbackModel : public QAbstractListModel
{
    Q_OBJECT
    Q_DISABLE_COPY(CallbackModel)

    // Properties:
    qulonglong  m_rowCount;
    bool        m_cache;
    qulonglong  m_cacheSize;
    int         m_requestDelay;
    QMutex      m_mutex;

    QHash< qulonglong, QVariant > m_records;
    QList< qulonglong > m_recordsNeeded;

    QTimer      m_requestTimer;

public:
    CallbackModel(QObject *parent = 0);
    ~CallbackModel();

    Q_PROPERTY( int requestDelay MEMBER m_requestDelay NOTIFY requestDelayChanged )
    Q_PROPERTY( qulonglong rows READ rows WRITE setRows NOTIFY rowCountChanged )
    Q_PROPERTY( bool cache MEMBER m_cache NOTIFY cacheChanged )
    Q_PROPERTY( bool cacheSize MEMBER m_cacheSize NOTIFY cacheSizeChanged )

    Q_INVOKABLE static CallbackModel *create() { return new CallbackModel(); }

    Q_INVOKABLE qulonglong rows() { return m_rowCount; }
    Q_INVOKABLE void setRows(qulonglong count);

    Q_INVOKABLE void setRecord( qulonglong index, QVariant record ); // 'record' should be convertable to QVariantList
    Q_INVOKABLE void setRecords( qulonglong first, QVariant records ); // 'records' should be convertable to QArray< QVariantList >

    int rowCount(const QModelIndex & parent = QModelIndex()) const;
    QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
    bool hasIndex(int row, int column, const QModelIndex & parent = QModelIndex()) const;
    QHash<int, QByteArray> roleNames() const;
/*
    bool canFetchMore(const QModelIndex & parent) const;
    void fetchMore(const QModelIndex & parent);
*/
protected:
    void requestData( qulonglong row );

protected slots:
    void slotRequestData();

signals:
    void requestDelayChanged();
    void rowCountChanged();
    void cacheChanged();
    void cacheSizeChanged();

    void recordsRequested( qulonglong first, qulonglong last );
};

#endif // CALLBACKMODEL_H

