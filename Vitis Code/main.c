/******************************************************************************
* Copyright (C) 2010 - 2022 Xilinx, Inc.  All rights reserved.
* Copyright (C) 2022 - 2023 Advanced Micro Devices, Inc.  All rights reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "netif/xadapter.h"
#include "platform.h"
#include "platform_config.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "lwip/dhcp.h"
#include "lwip/tcp.h"
#include "lwip/err.h"

#include "xaxidma.h"
#include "xdebug.h"

/************** For AXI DMA ******************/

#define DMA_DEV_ID						XPAR_AXIDMA_0_DEVICE_ID
#define MEM_BASE_ADDR					0x01000000 
#define RX_BD_SPACE_BASE				(MEM_BASE_ADDR)
#define RX_BD_SPACE_HIGH				(MEM_BASE_ADDR + 0x00FFFFFF) 
#define TX_BD_SPACE_BASE				(MEM_BASE_ADDR + 0x01000000) 
#define TX_BD_SPACE_HIGH				(MEM_BASE_ADDR + 0x01FFFFFF) 
#define TX_BUFFER_BASE					(MEM_BASE_ADDR + 0x02000000) 
#define RX_BUFFER_BASE					(MEM_BASE_ADDR + 0x03000000) 

#define NUMBER_OF_PKTS_TO_TRANSFER 		100 // data frame
#define MAX_TX_PKT_LEN					80 // 80 byte = 640 bit per TX packet
#define MAX_RX_PKT_LEN					88 // 88 byte = 704 bit per RX packet
#define NUMBER_OF_TX_BDS_PER_PKT		1 // data packet
#define NUMBER_OF_RX_BDS_PER_PKT		1
#define NUMBER_OF_TX_BDS_TO_TRANSFER	(NUMBER_OF_PKTS_TO_TRANSFER * NUMBER_OF_TX_BDS_PER_PKT)
#define NUMBER_OF_RX_BDS_TO_TRANSFER	(NUMBER_OF_PKTS_TO_TRANSFER * NUMBER_OF_RX_BDS_PER_PKT)

extern void xil_printf(const char *format, ...);

int TxSetup(XAxiDma *AxiDmaInstPtr);
int RxSetup(XAxiDma *AxiDmaInstPtr);
int SendData(XAxiDma *AxiDmaInstPtr);
int ReceiveData(XAxiDma *AxiDmaInstPtr, struct tcp_pcb *tpcb);


XAxiDma AxiDma;



/************** For TCP Server ******************/


extern volatile int dhcp_timoutcntr;
err_t dhcp_start(struct netif *netif);

int start_application();
void tcp_fasttmr(void);
void tcp_slowtmr(void);

// missing declaration in lwIP
void lwip_init();

extern volatile int TcpFastTmrFlag;
extern volatile int TcpSlowTmrFlag;
struct netif server_netif;
struct netif *endec_server_netif;

void print_ip(char *msg, ip_addr_t *ip);
void print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw);

u32 bytes_to_send; 
u32	*write_addr = (u32 *) RX_BUFFER_BASE; 

int buffer_count = 0;
u32 buffer_addr = TX_BUFFER_BASE;

int main()
{
	xil_printf("\n\r\n\r------ lwIP TCP Encoder-Decoder Server ------\n\r");
	
	
	/************** For AXI DMA ******************/
	int Status;
	XAxiDma_Config *Config;

	Config = XAxiDma_LookupConfig(DMA_DEV_ID);
	if (!Config) {
		xil_printf("No config found for %d\r\n", DMA_DEV_ID);
		return XST_FAILURE;
	}

	// Initialize DMA engine
	XAxiDma_CfgInitialize(&AxiDma, Config);
	if (!XAxiDma_HasSg(&AxiDma)) {
		xil_printf("Device configured as Simple mode \r\n");
		return XST_FAILURE;
	}

	Status = TxSetup(&AxiDma);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed TX setup\r\n");
		return XST_FAILURE;
	}

	Status = RxSetup(&AxiDma);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed RX setup\r\n");
		return XST_FAILURE;
	}



	/************** For TCP Server ******************/
	ip_addr_t ipaddr, netmask, gw;
	unsigned char mac_ethernet_address[] = { 0x00, 0x0a, 0x35, 0x00, 0x01, 0x02 };
	endec_server_netif = &server_netif;
	init_platform();
	ipaddr.addr = 0;
	gw.addr = 0;
	netmask.addr = 0;
	lwip_init();
	/* Add network interface to the netif_list, and set it as default */
	if (!xemac_add(endec_server_netif, &ipaddr, &netmask, &gw, mac_ethernet_address, PLATFORM_EMAC_BASEADDR)) {
		xil_printf("Error adding N/W interface\n\r");
		return XST_FAILURE;
	}
	netif_set_default(endec_server_netif);
	platform_enable_interrupts();
	netif_set_up(endec_server_netif);
	dhcp_start(endec_server_netif);
	dhcp_timoutcntr = 240; 
	while (((endec_server_netif->ip_addr.addr) == 0) && (dhcp_timoutcntr > 0))
		xemacif_input(endec_server_netif);
	
	if (dhcp_timoutcntr <= 0) {
		if ((endec_server_netif->ip_addr.addr) == 0) {
			xil_printf("DHCP Timeout\r\n");
			xil_printf("Configuring default IP of 192.168.1.10\r\n");
			IP4_ADDR(&(endec_server_netif->ip_addr),  192, 168,   1, 10);
			IP4_ADDR(&(endec_server_netif->netmask), 255, 255, 255,  0);
			IP4_ADDR(&(endec_server_netif->gw),      192, 168,   1,  1);
		}
	}
	ipaddr.addr = endec_server_netif->ip_addr.addr;
	gw.addr = endec_server_netif->gw.addr;
	netmask.addr = endec_server_netif->netmask.addr;
	print_ip_settings(&ipaddr, &netmask, &gw);
	start_application();


	/************** Main Loop ******************/

	// receive and process packets
	while (1) {
		if (TcpFastTmrFlag) {
			tcp_fasttmr();
			TcpFastTmrFlag = 0;
		}
		if (TcpSlowTmrFlag) {
			tcp_slowtmr();
			TcpSlowTmrFlag = 0;
		}
		xemacif_input(endec_server_netif);
	}

	return XST_SUCCESS;
}





/************** For TCP Server ******************/

void print_ip(char *msg, ip_addr_t *ip)
{
	print(msg);
	xil_printf("%d.%d.%d.%d\n\r", ip4_addr1(ip), ip4_addr2(ip), ip4_addr3(ip), ip4_addr4(ip));
}

void print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw)
{
	print_ip("Board IP: ", ip);
	print_ip("Netmask : ", mask);
	print_ip("Gateway : ", gw);
}


err_t push_data(struct tcp_pcb *tpcb) 
{
    u32 packet_size = bytes_to_send;
    u32 max_bytes = tcp_sndbuf(tpcb);
    err_t status;

    if (bytes_to_send == 0){
        return ERR_OK;
	}

	if (packet_size >= max_bytes){
		packet_size = max_bytes;
	}
	else{
		packet_size = packet_size;
	}
	
    // write to the LWIP library's buffer
    status = tcp_write(tpcb, (void*)write_addr, packet_size, 0); // 0, TCP_WRITE_FLAG_COPY, TCP_WRITE_FLAG_MORE
	if(status != ERR_OK)
		xil_printf("tcp_write error\r\n");

    if (packet_size > bytes_to_send)
        bytes_to_send = 0;
    else
        bytes_to_send -= packet_size;

	write_addr = (u32*)((u8*)write_addr + packet_size);

    return status;
}


err_t sent_callback(void *arg, struct tcp_pcb *tpcb, u16_t len) {
    if (bytes_to_send <= 0){
		tcp_sent(tpcb, NULL);
		tcp_recv(tpcb, NULL); 
		return ERR_OK;
	}

    return push_data(tpcb);
}


err_t recv_callback(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err)
{
/* do not read the packet if we are not in ESTABLISHED state */
	if (err != ERR_OK || !p) {
		tcp_close(tpcb); 
		tcp_sent(tpcb, NULL);
		tcp_recv(tpcb, NULL);
		pbuf_free(p);
		return ERR_OK;
	}


    // indicate that the packet has been received
	tcp_recved(tpcb, p->tot_len); 

	bytes_to_send = NUMBER_OF_PKTS_TO_TRANSFER*MAX_RX_PKT_LEN;  

    memcpy((void*)buffer_addr, p->payload, p->len);

	buffer_count += p->len;
	buffer_addr += p->len;

	pbuf_free(p);

	int Status;

	if(buffer_count == NUMBER_OF_PKTS_TO_TRANSFER*MAX_TX_PKT_LEN){
		xil_printf("[STATUS] Received %d data frames in %d bytes from client\r\n", NUMBER_OF_PKTS_TO_TRANSFER, NUMBER_OF_PKTS_TO_TRANSFER*MAX_TX_PKT_LEN);
		Status = SendData(&AxiDma);
		if (Status != XST_SUCCESS)
			xil_printf("Failed send packet\r\n");

		Status = ReceiveData(&AxiDma, tpcb);
		if (Status != XST_SUCCESS)
			xil_printf("Data check failed\r\n");

		buffer_count = 0;
		buffer_addr = TX_BUFFER_BASE;
	}


    return err;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	int connection = 1;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);

	/* set the sent callback for this connection */
	tcp_sent(newpcb, sent_callback); 

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void*)(UINTPTR)connection);

	/* increment for subsequent accepted connections */
	connection++;

	return ERR_OK;
}

int start_application()
{
	struct tcp_pcb *pcb;
	err_t err;
	unsigned port = 4015;

	/* create new TCP PCB structure */
	pcb = tcp_new_ip_type(IPADDR_TYPE_V4);
	if (!pcb) {
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}

	/* bind to specified @port */
	err = tcp_bind(pcb, IP_ANY_TYPE, port);
	if (err != ERR_OK) {
		xil_printf("Unable to bind to port %d: err = %d\n\r", port, err);
		return -2;
	}

	/* we do not need any arguments to callback functions */
	tcp_arg(pcb, NULL);

	/* listen for connections */
	pcb = tcp_listen(pcb);
	if (!pcb) {
		xil_printf("Out of memory while tcp_listen\n\r");
		return -3;
	}

	/* specify callback to use for incoming connections */
	tcp_accept(pcb, accept_callback);

	xil_printf("lwIP TCP Encoder-Decoder Server started listening @ port %d\n\r", port);

	return 0;
}







/************** For AXI DMA ******************/

int RxSetup(XAxiDma *AxiDmaInstPtr)
{
	XAxiDma_BdRing *RxRingPtr;
	int Status;
	XAxiDma_Bd BdZero;
	XAxiDma_Bd *BdPtr;
	XAxiDma_Bd *BdCurPtr;
	int BdCount;
	int FreeBdCount;
	UINTPTR RxBufferPtr;

	RxRingPtr = XAxiDma_GetRxRing(&AxiDma);

	// Setup Rx BD space
	BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT, RX_BD_SPACE_HIGH - RX_BD_SPACE_BASE + 1);

	Status = XAxiDma_BdRingCreate(RxRingPtr, RX_BD_SPACE_BASE, RX_BD_SPACE_BASE, XAXIDMA_BD_MINIMUM_ALIGNMENT, BdCount);
	if (Status != XST_SUCCESS) {
		xil_printf("Rx bd create failed with %d\r\n", Status);
		return XST_FAILURE;
	}

	// Setup a BD template for the Rx channel. Then copy it to every RX BD.
	XAxiDma_BdClear(&BdZero);
	Status = XAxiDma_BdRingClone(RxRingPtr, &BdZero);
	if (Status != XST_SUCCESS) {
		xil_printf("Rx bd zero failed with %d\r\n", Status);
		return XST_FAILURE;
	}

	// Attach buffers to RxBD ring so we are ready to receive packets
	FreeBdCount = XAxiDma_BdRingGetFreeCnt(RxRingPtr);

	Status = XAxiDma_BdRingAlloc(RxRingPtr, FreeBdCount, &BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Rx bd alloc failed with %d\r\n", Status);
		return XST_FAILURE;
	}

	BdCurPtr = BdPtr;
	RxBufferPtr = RX_BUFFER_BASE;

	for (int i = 0; i < FreeBdCount; i++) {
		Status = XAxiDma_BdSetBufAddr(BdCurPtr, RxBufferPtr);
		if (Status != XST_SUCCESS) {
			xil_printf("Rx set buffer addr %x on BD %x failed %d\r\n", (unsigned int)RxBufferPtr, (UINTPTR)BdCurPtr, Status);
			return XST_FAILURE;
		}

		Status = XAxiDma_BdSetLength(BdCurPtr, MAX_RX_PKT_LEN, RxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) {
			xil_printf("Rx set length %d on BD %x failed %d\r\n", MAX_RX_PKT_LEN, (UINTPTR)BdCurPtr, Status);
			return XST_FAILURE;
		}

		/* Receive BDs do not need to set anything for the control
		 * The hardware will set the SOF/EOF bits per stream status
		 */
		XAxiDma_BdSetCtrl(BdCurPtr, 0);
		XAxiDma_BdSetId(BdCurPtr, RxBufferPtr);

		RxBufferPtr += MAX_RX_PKT_LEN;
		BdCurPtr = (XAxiDma_Bd *)XAxiDma_BdRingNext(RxRingPtr, BdCurPtr);
	}

	Status = XAxiDma_BdRingToHw(RxRingPtr, FreeBdCount, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Rx ToHw failed with %d\r\n", Status);
		return XST_FAILURE;
	}

	/* Start RX DMA channel */
	Status = XAxiDma_BdRingStart(RxRingPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Rx start BD ring failed with %d\r\n", Status);
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


int TxSetup(XAxiDma *AxiDmaInstPtr)
{
	XAxiDma_BdRing *TxRingPtr = XAxiDma_GetTxRing(&AxiDma);
	XAxiDma_Bd BdZero;
	int Status;
	u32 BdCount;

	/* Setup TxBD space  */
	BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT, (UINTPTR)TX_BD_SPACE_HIGH - (UINTPTR)TX_BD_SPACE_BASE + 1);

	Status = XAxiDma_BdRingCreate(TxRingPtr, TX_BD_SPACE_BASE, TX_BD_SPACE_BASE, XAXIDMA_BD_MINIMUM_ALIGNMENT, BdCount);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed create BD ring\r\n");
		return XST_FAILURE;
	}

	/*
	 * Like the RxBD space, we create a template and set all BDs to be the
	 * same as the template. The sender has to set up the BDs as needed.
	 */
	XAxiDma_BdClear(&BdZero);
	Status = XAxiDma_BdRingClone(TxRingPtr, &BdZero);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed zero BDs\r\n");
		return XST_FAILURE;
	}

	/* Start the TX channel */
	Status = XAxiDma_BdRingStart(TxRingPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed bd start\r\n");
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

int ReceiveData(XAxiDma *AxiDmaInstPtr, struct tcp_pcb *tpcb)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_BdRing *RxRingPtr;
	XAxiDma_Bd *BdPtr;
	u32 ProcessedBdCount = 0;
	u32 FreeBdCount;
	int Status;

	TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);
	RxRingPtr = XAxiDma_GetRxRing(AxiDmaInstPtr);

	/* Wait until the TX transactions are done */
	while (ProcessedBdCount < NUMBER_OF_TX_BDS_TO_TRANSFER){
		ProcessedBdCount += XAxiDma_BdRingFromHw(TxRingPtr, XAXIDMA_ALL_BDS, &BdPtr);
	}

	/* Free all processed TX BDs for future transmission */
	Status = XAxiDma_BdRingFree(TxRingPtr, ProcessedBdCount, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed to free TX BDs\r\n");
		return XST_FAILURE;
	}

		// Wait until the data has been received by the Rx channel 
	ProcessedBdCount = 0;
	while (ProcessedBdCount < NUMBER_OF_RX_BDS_TO_TRANSFER){
		ProcessedBdCount += XAxiDma_BdRingFromHw(RxRingPtr, XAXIDMA_ALL_BDS, &BdPtr);
	}

	// must read all data before freeing processed RX BD
	Xil_DCacheInvalidateRange((UINTPTR)RX_BUFFER_BASE, MAX_RX_PKT_LEN * NUMBER_OF_RX_BDS_TO_TRANSFER);
	push_data(tpcb);


	// /* Free all processed RX BDs for future transmission */
	Status = XAxiDma_BdRingFree(RxRingPtr, ProcessedBdCount, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("free bd failed\r\n");
		return XST_FAILURE;
	}

	// /* Return processed BDs to RX channel so we are ready to receive new
	//  * packets:
	//  *    - Allocate all free RX BDs
	//  *    - Pass the BDs to RX channel
	//  */
	
	FreeBdCount = XAxiDma_BdRingGetFreeCnt(RxRingPtr);
	
	Status = XAxiDma_BdRingAlloc(RxRingPtr, FreeBdCount, &BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("bd alloc failed\r\n");
		return XST_FAILURE;
	}


	XAxiDma_Bd *BdCurPtr = BdPtr;
	UINTPTR RxBufferPtr = (UINTPTR)write_addr;

	for (int i = 0; i < FreeBdCount; i++) {
		Status = XAxiDma_BdSetBufAddr(BdCurPtr, RxBufferPtr);
		if (Status != XST_SUCCESS) {
			xil_printf("Rx set buffer addr %x on BD %x failed %d\r\n", (unsigned int)RxBufferPtr, (UINTPTR)BdCurPtr, Status);
			return XST_FAILURE;
		}

		Status = XAxiDma_BdSetLength(BdCurPtr, MAX_RX_PKT_LEN, RxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) {
			xil_printf("Rx set length %d on BD %x failed %d\r\n", MAX_RX_PKT_LEN, (UINTPTR)BdCurPtr, Status);
			return XST_FAILURE;
		}

		/* Receive BDs do not need to set anything for the control
		 * The hardware will set the SOF/EOF bits per stream status
		 */
		XAxiDma_BdSetCtrl(BdCurPtr, 0);
		XAxiDma_BdSetId(BdCurPtr, RxBufferPtr);

		RxBufferPtr += MAX_RX_PKT_LEN;
		BdCurPtr = (XAxiDma_Bd *)XAxiDma_BdRingNext(RxRingPtr, BdCurPtr);
	}


	Status = XAxiDma_BdRingToHw(RxRingPtr, FreeBdCount, BdPtr);

	return XST_SUCCESS;
}


int SendData(XAxiDma *AxiDmaInstPtr)
{
	XAxiDma_BdRing *TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);
	XAxiDma_Bd *BdPtr, *BdCurPtr;
	int Status;
	UINTPTR BufferAddr;

	if (MAX_TX_PKT_LEN * NUMBER_OF_TX_BDS_PER_PKT > TxRingPtr->MaxTransferLen) {
		xil_printf("Invalid total per packet transfer length for the packet %d/%d\r\n", MAX_TX_PKT_LEN * NUMBER_OF_TX_BDS_PER_PKT, TxRingPtr->MaxTransferLen);
		return XST_INVALID_PARAM;
	}

	Xil_DCacheFlushRange((UINTPTR)TX_BUFFER_BASE, MAX_TX_PKT_LEN * NUMBER_OF_TX_BDS_TO_TRANSFER);
	Xil_DCacheFlushRange((UINTPTR)RX_BUFFER_BASE, MAX_RX_PKT_LEN * NUMBER_OF_RX_BDS_TO_TRANSFER);

	Status = XAxiDma_BdRingAlloc(TxRingPtr, NUMBER_OF_TX_BDS_TO_TRANSFER, &BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed bd alloc\r\n");
		return XST_FAILURE;
	}

	BufferAddr = (UINTPTR)TX_BUFFER_BASE;
	BdCurPtr = BdPtr;

	/*
	 * Set up the BD using the information of the packet to transmit
	 * Each transfer has NUMBER_OF_BDS_PER_PKT BDs
	 */
	for (int i = 0; i < NUMBER_OF_PKTS_TO_TRANSFER; i++) {
		for (int j = 0; j < NUMBER_OF_TX_BDS_PER_PKT; j++) {
			u32 CrBits = 0;

			Status = XAxiDma_BdSetBufAddr(BdCurPtr, BufferAddr);
			if (Status != XST_SUCCESS) {
				xil_printf("Tx set buffer addr %x on BD %x failed %d\r\n", (unsigned int)BufferAddr, (UINTPTR)BdCurPtr, Status);
				return XST_FAILURE;
			}

			Status = XAxiDma_BdSetLength(BdCurPtr, MAX_TX_PKT_LEN, TxRingPtr->MaxTransferLen);
			if (Status != XST_SUCCESS) {
				xil_printf("Tx set length %d on BD %x failed %d\r\n", MAX_TX_PKT_LEN, (UINTPTR)BdCurPtr, Status);
				return XST_FAILURE;
			}

			if (j == 0) // start of packet
				CrBits |= XAXIDMA_BD_CTRL_TXSOF_MASK;

			if (j == (NUMBER_OF_TX_BDS_PER_PKT - 1)) // last of packet
				CrBits |= XAXIDMA_BD_CTRL_TXEOF_MASK;

			XAxiDma_BdSetCtrl(BdCurPtr, CrBits);
			XAxiDma_BdSetId(BdCurPtr, BufferAddr);

			BufferAddr += MAX_TX_PKT_LEN;
			BdCurPtr = (XAxiDma_Bd *)XAxiDma_BdRingNext(TxRingPtr, BdCurPtr);
		}
	}

	/* Give the BD to hardware */
	Status = XAxiDma_BdRingToHw(TxRingPtr, NUMBER_OF_TX_BDS_TO_TRANSFER, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed to hw, length %d\r\n", (int)XAxiDma_BdGetLength(BdPtr, TxRingPtr->MaxTransferLen));
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}