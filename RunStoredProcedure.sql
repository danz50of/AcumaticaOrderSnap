USE [PEERLESS_ORDER_HISTORY]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[PopulateOrderDelta]
		@SnapshotDate = '2024-10-07',
		@PrevSnapshotDate = '2024-10-06'

SELECT	'Return Value' = @return_value

GO
